extends RefCounted
class_name CanglanUpdateChannel
## Immutable in the base APK. Keep this URL empty until a real PUBLIC HTTPS
## update feed is provisioned. Never use the private gameplay repository URL.
const CHANNEL: String = "android-preview"
const MANIFEST_URL: String = "https://160701541-cell.github.io/xinyanshuo/android-preview/latest.json"
## RSA-3072 public verification key. Its matching PRIVATE key is never stored
## in source control, exported APK or CI logs.
const PUBLIC_KEY_PEM: String = """-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEApffsufhTL6uBCguX7tFX
KsZ3tasXzU5mR+NiMQT/+TOcnJjEMwfWZjHxjeS5ya6A2iGLAS8jZnZXtpnyDZeO
8DfvS/eXR3VvwdbghTF1bioezrUxbhLZFdd00dm6jAG7m+5wYTzB2UOvyX/X8n8N
NGpQMDa5wowUow7Rza2ao6VsEapvjsl2lzlnQwzOSwwyQI0qYkB1mSNtxjTio5uQ
dlsKvu4xLSAaDXKk7TkIVOEhmNUfvII5m1vOgaoobpSHhDndlmug7YEZIggy14TD
NbiixU1RgpDKdybxRSrHVubrHVbuc6jp6mdrX7pLqtm26/LDk+QJc1Q036UTTLhL
pjKk3QQBYNaKjl9JT49cdCosDwxTitCKzeM+b/qWOdyGVEErIZd+++RXlUTvPp/a
HLy1Xjqa1nGtBe96vM86lI5hSsU1oFXywsbK1c04DJso4ESCrw8t/sKUKXkhPUuS
LZvnifMVGrkrp84IxCLxBuKucX8pCBL3BbDnWrmpQ7/FAgMBAAE=
-----END PUBLIC KEY-----"""
