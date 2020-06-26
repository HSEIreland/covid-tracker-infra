resource "aws_wafregional_web_acl" "acl" {
  name        = "${module.labels.id}-waf"
  metric_name = "ftWaf${var.environment}"

  tags = module.labels.tags

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 10
    rule_id  = aws_wafregional_rule.sqli.id
    type     = "REGULAR"
  }

  rule {
    action {
      type = "BLOCK"
    }

    priority = 20
    rule_id  = aws_wafregional_rule.xss.id
    type     = "REGULAR"
  }
}

## slq injection
resource "aws_wafregional_sql_injection_match_set" "sqli" {
  name = "${module.labels.id}-generic-sqli"

  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "URI"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "URI"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "HEADER"
      data = "cookie"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "HEADER"
      data = "cookie"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "HEADER"
      data = "Authorization"
    }
  }

  sql_injection_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "HEADER"
      data = "Authorization"
    }
  }
}

resource "aws_wafregional_rule" "sqli" {
  name        = "${module.labels.id}-generic-sqli"
  metric_name = "ftSQLI${var.environment}"

  predicate {
    data_id = aws_wafregional_sql_injection_match_set.sqli.id
    negated = false
    type    = "SqlInjectionMatch"
  }
}

## xss
resource "aws_wafregional_xss_match_set" "xss" {
  name = "${module.labels.id}-generic-xss"

  xss_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  xss_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "BODY"
    }
  }

  xss_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "URI"
    }
  }

  xss_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "URI"
    }
  }

  xss_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  xss_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  xss_match_tuple {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "HEADER"
      data = "cookie"
    }
  }

  xss_match_tuple {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "HEADER"
      data = "cookie"
    }
  }
}

resource "aws_wafregional_rule" "xss" {
  name        = "${module.labels.id}-generic-xss"
  metric_name = "ftXSS${var.environment}"

  predicate {
    data_id = aws_wafregional_xss_match_set.xss.id
    negated = false
    type    = "XssMatch"
  }
}

resource "aws_wafregional_web_acl_association" "gateway" {
  resource_arn = aws_api_gateway_stage.live.arn
  web_acl_id   = aws_wafregional_web_acl.acl.id
}

resource "aws_wafregional_web_acl_association" "api" {
  resource_arn = aws_lb.api.arn
  web_acl_id   = aws_wafregional_web_acl.acl.id
}

resource "aws_wafregional_web_acl_association" "push" {
  resource_arn = aws_lb.push.arn
  web_acl_id   = aws_wafregional_web_acl.acl.id
}
