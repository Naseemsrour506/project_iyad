def normalize_text(text: str) -> str:
    return " ".join(text.strip().lower().split())


def analyze_message(text: str) -> dict:
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
        "דפוק"
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
            "explanation": "The message contains humiliating or socially harmful language."
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
