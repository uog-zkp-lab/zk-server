pub fn extract_attribute_names(attrs: &serde_json::Value) -> Vec<String> {
    attrs
        .get("attributes")
        .and_then(|a| a.as_array())
        .map(|attributes| {
            attributes
                .iter()
                .filter_map(|attr| {
                    attr.get("name")
                        .and_then(serde_json::Value::as_str)
                        .map(String::from)
                })
                .collect()
        })
        .unwrap_or_default()
}