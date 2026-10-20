"""
INSECURE, PUBLIC, DETERMINISTIC LAB TEST SIGNING ONLY.
Everyone can reproduce this key. Never use for production or sensitive user data.
It exists to prevent debug test APKs randomly changing signatures across CI runs.
A private production signing key belongs in GitHub Actions protected Secrets.
"""
import datetime
import hashlib
import math
import os
from pathlib import Path
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

E = 65537
SEED = b"ZhiYin-Proto-Test-Key-2026-PUBLIC-NOT-FOR-PRODUCTION"
def prime(which: bytes) -> int:
    i = 0
    small_primes = (3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59)
    while True:
        candidate = int.from_bytes(hashlib.shake_256(SEED + which + i.to_bytes(8, "big")).digest(128), "big")
        candidate |= (1 << 1023) | 1
        i += 1
        if math.gcd(candidate - 1, E) != 1: continue
        if any(candidate % p == 0 for p in small_primes): continue
        d = candidate - 1
        s = 0
        while d % 2 == 0: s += 1; d //= 2
        probable = True
        for trial in range(24):
            base = 2 + int.from_bytes(
                hashlib.sha256(SEED + which + i.to_bytes(8, "big") + bytes((trial,))).digest(), "big"
            ) % (candidate - 3)
            x = pow(base, d, candidate)
            if x == 1 or x == candidate - 1: continue
            for _ in range(s - 1):
                x = pow(x, 2, candidate)
                if x == candidate - 1: break
            else:
                probable = False
                break
        if probable: return candidate

p, q = prime(b"P"), prime(b"Q")
if p == q: raise RuntimeError("Invalid RSA primes")
n = p * q
d = pow(E, -1, (p - 1) * (q - 1))
private = rsa.RSAPrivateNumbers(
    p=p, q=q, d=d, dmp1=d % (p - 1), dmq1=d % (q - 1), iqmp=pow(q, -1, p),
    public_numbers=rsa.RSAPublicNumbers(E, n)
).private_key()

subject = x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, "ZhiYin Public Prototype Test Key"),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Unsafe Test Signing - Do Not Trust"),
])
cert = (
    x509.CertificateBuilder().subject_name(subject).issuer_name(subject)
    .public_key(private.public_key()).serial_number(0x2602026026202026)
    .not_valid_before(datetime.datetime(2026, 1, 1, tzinfo=datetime.timezone.utc))
    .not_valid_after(datetime.datetime(2046, 1, 1, tzinfo=datetime.timezone.utc))
    .sign(private, hashes.SHA256())
)
password = b"PublicLabOnly2026"
out = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "zhiyin-test-signing.p12"
out.write_bytes(pkcs12.serialize_key_and_certificates(
    name=b"zhiyin-lab", key=private, cert=cert, cas=None,
    encryption_algorithm=serialization.BestAvailableEncryption(password)
))
print("INSECURE PUBLIC TEST KEY ONLY. Stable SHA256 cert fingerprint:", cert.fingerprint(hashes.SHA256()).hex())
print(out)
