import json
import os
import re
from typing import Any

from app.core.config import (
    AI_PROVIDER,
    GEMINI_API_KEY,
    GEMINI_MODEL
)


VALID_CATEGORIES = {
    "Normal",
    "Insult",
    "Threat",
    "Harassment",
    "Bullying"
}

VALID_RISK_LEVELS = {
    "Low",
    "Medium",
    "High"
}


def normalize_text(text: str) -> str:
    return " ".join(text.strip().lower().split())


def analyze_message(text: str) -> dict:
    if should_use_gemini():
        gemini_result = analyze_message_with_gemini(text)

        if gemini_result is not None:
            return gemini_result

    return analyze_message_rule_based(text)


def should_use_gemini() -> bool:
    if AI_PROVIDER != "gemini":
        return False

    if not GEMINI_API_KEY:
        return False

    # During tests we avoid external API calls.
    # This keeps pytest fast, stable, and free from Gemini quota usage.
    if os.getenv("PYTEST_CURRENT_TEST"):
        return False

    return True


def analyze_message_rule_based(text: str) -> dict:
    normalized_text = normalize_text(text)

    threat_words = [
        "אהרוג",
        "נהרוג",
        "תמות",
        "אדקור",
        "מאיים"
    ]

    bullying_phrases = [
        "אף אחד לא אוהב אותך",
        "כולם שונאים אותך",
        "לך מפה",
        "לא רוצים אותך",
        "אתה לא שייך"
    ]

    insult_words = [
        "אפס",
        "מטומטם",
        "טיפש",
        "מכוער",
        "דפוק",
        "מניאק",
        "אידיוט",
        "סתום",
        "מפגר",
        "זבל",
        "חרא"
    ]

    harassment_words = [
        "אני אמשיך",
        "לא אעזוב אותך",
        "כל יום",
        "מציק",
        "הטרדה"
    ]

    if any(word in normalized_text for word in threat_words):
        return {
            "category": "Threat",
            "risk_level": "High",
            "confidence": 0.95,
            "explanation": "The message contains threatening language."
        }

    if any(phrase in normalized_text for phrase in bullying_phrases):
        return {
            "category": "Bullying",
            "risk_level": "High",
            "confidence": 0.88,
            "explanation": (
                "The message contains humiliating or socially harmful language."
            )
        }

    if any(word in normalized_text for word in insult_words):
        return {
            "category": "Insult",
            "risk_level": "Medium",
            "confidence": 0.82,
            "explanation": "The message contains offensive language."
        }

    if any(word in normalized_text for word in harassment_words):
        return {
            "category": "Harassment",
            "risk_level": "Medium",
            "confidence": 0.78,
            "explanation": "The message may contain harassment-related language."
        }

    return {
        "category": "Normal",
        "risk_level": "Low",
        "confidence": 0.97,
        "explanation": "No harmful content was detected."
    }


def analyze_message_with_gemini(text: str) -> dict | None:
    try:
        from google import genai
    except Exception:
        return None

    prompt = build_gemini_prompt(text)

    try:
        client = genai.Client(
            api_key=GEMINI_API_KEY
        )

        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt
        )

        response_text = getattr(response, "text", None)

        if not response_text:
            return None

        raw_result = parse_json_response(response_text)

        return validate_classifier_result(raw_result)
    except Exception:
        return None


def build_gemini_prompt(message: str) -> str:
    return f"""
You are a Hebrew cyberbullying and child-safety classifier.

Analyze the following message and return ONLY valid JSON.
Do not include markdown.
Do not include explanations outside the JSON.

Allowed categories:
- Normal
- Insult
- Threat
- Harassment
- Bullying

Allowed risk levels:
- Low
- Medium
- High

Rules:
- Use "Threat" and "High" when the message contains direct physical harm, death threats, stabbing, killing, or clear danger.
- Use "Bullying" and usually "High" when the message humiliates, excludes, socially attacks, or tells the child nobody wants them.
- Use "Insult" and usually "Medium" for direct offensive language, curses, or name-calling.
- Use "Harassment" and usually "Medium" when the message suggests repeated unwanted contact or persistent bothering.
- Use "Normal" and "Low" for harmless messages.
- The explanation must be short, clear, and parent-friendly.
- The confidence must be a number between 0 and 1.

Return exactly this JSON structure:
{{
  "category": "Normal",
  "risk_level": "Low",
  "confidence": 0.0,
  "explanation": "Short explanation here."
}}

Message:
{message}
""".strip()


def parse_json_response(response_text: str) -> dict[str, Any]:
    cleaned_text = response_text.strip()

    cleaned_text = re.sub(
        r"^```json\s*",
        "",
        cleaned_text,
        flags=re.IGNORECASE
    )

    cleaned_text = re.sub(
        r"^```\s*",
        "",
        cleaned_text
    )

    cleaned_text = re.sub(
        r"\s*```$",
        "",
        cleaned_text
    )

    return json.loads(cleaned_text)


def validate_classifier_result(raw_result: dict[str, Any]) -> dict | None:
    category = str(raw_result.get("category", "")).strip()
    risk_level = str(raw_result.get("risk_level", "")).strip()
    explanation = str(raw_result.get("explanation", "")).strip()

    try:
        confidence = float(raw_result.get("confidence", 0))
    except (TypeError, ValueError):
        confidence = 0.0

    confidence = max(0.0, min(confidence, 1.0))

    if category not in VALID_CATEGORIES:
        return None

    if risk_level not in VALID_RISK_LEVELS:
        return None

    if not explanation:
        explanation = "The message was analyzed by the AI classifier."

    return {
        "category": category,
        "risk_level": risk_level,
        "confidence": confidence,
        "explanation": explanation
    }
