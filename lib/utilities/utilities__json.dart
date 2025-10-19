String jsonAddQuotes(String json) {

    json = json.replaceAll('{', '{"');
    json = json.replaceAll(': ', '": "');
    json = json.replaceAll(', ', '", "');
    json = json.replaceAll('}', '"}');

    json = json.replaceAll('"{', '{');
    json = json.replaceAll('}"', '}');

    return json;
}