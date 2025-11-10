# Task Description

修改 renovate.json 为：

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>konflux-ci/mintmaker//config/renovate/renovate.json"],
  "labels": ["dependencies", "ok-to-test"],
  "gomod": {
    "enabled": false
  },
  "timezone": "Asia/Shanghai",
  "schedule": ["on monday"]
}
```
