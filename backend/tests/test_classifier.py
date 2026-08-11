from app.services.classifier import analyze_message


def test_normal_message():
    result = analyze_message("שלום, מה שלומך?")

    assert result["category"] == "Normal"
    assert result["risk_level"] == "Low"


def test_insult_message():
    result = analyze_message("אתה טיפש")

    assert result["category"] == "Insult"
    assert result["risk_level"] == "Medium"


def test_threat_message():
    result = analyze_message("אני אהרוג אותך")

    assert result["category"] == "Threat"
    assert result["risk_level"] == "High"


def test_bullying_message():
    result = analyze_message("אף אחד לא אוהב אותך")

    assert result["category"] == "Bullying"
    assert result["risk_level"] == "High"


def test_harassment_message():
    result = analyze_message("אני לא אעזוב אותך")

    assert result["category"] == "Harassment"
    assert result["risk_level"] == "Medium"
