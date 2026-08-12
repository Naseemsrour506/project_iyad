from app.services import classifier


def test_rule_based_classifier_still_detects_insult():
    result = classifier.analyze_message_rule_based(
        "אתה מניאק גדול"
    )

    assert result["category"] == "Insult"
    assert result["risk_level"] == "Medium"


def test_json_response_parser_accepts_plain_json():
    result = classifier.parse_json_response(
        '{"category":"Insult","risk_level":"Medium","confidence":0.8,"explanation":"Offensive language."}'
    )

    assert result["category"] == "Insult"
    assert result["risk_level"] == "Medium"


def test_classifier_result_validation_rejects_invalid_category():
    result = classifier.validate_classifier_result(
        {
            "category": "Unknown",
            "risk_level": "Low",
            "confidence": 0.5,
            "explanation": "Invalid category."
        }
    )

    assert result is None


def test_gemini_is_disabled_during_pytest(monkeypatch):
    monkeypatch.setattr(
        classifier,
        "AI_PROVIDER",
        "gemini"
    )
    monkeypatch.setattr(
        classifier,
        "GEMINI_API_KEY",
        "fake-key"
    )
    monkeypatch.setenv(
        "PYTEST_CURRENT_TEST",
        "fake-test"
    )

    assert classifier.should_use_gemini() is False
