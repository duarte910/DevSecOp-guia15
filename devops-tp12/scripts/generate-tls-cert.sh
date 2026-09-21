#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="${PROJECT_DIR}/certs"
CERT="${CERT_DIR}/tls.crt"
KEY="${CERT_DIR}/tls.key"
HOST="devops-portfolio.local"
NAMESPACE="devops-portfolio"
SECRET_NAME="devops-portfolio-tls"

mkdir -p "${CERT_DIR}"
chmod 700 "${CERT_DIR}"

validate_pair() {
  openssl x509 -in "${CERT}" -noout -checkend 86400 >/dev/null || return 1
  openssl x509 -in "${CERT}" -noout -checkhost "${HOST}" 2>/dev/null | grep -q 'does match certificate' || return 1
  cert_pub="$(openssl x509 -in "${CERT}" -pubkey -noout | openssl pkey -pubin -outform DER 2>/dev/null | sha256sum | awk '{print $1}')"
  key_pub="$(openssl pkey -in "${KEY}" -pubout -outform DER 2>/dev/null | sha256sum | awk '{print $1}')"
  [ -n "${cert_pub}" ] && [ "${cert_pub}" = "${key_pub}" ]
}

if [ ! -e "${CERT}" ] && [ ! -e "${KEY}" ]; then
  printf 'Generando certificado autofirmado para %s...\n' "${HOST}"
  umask 077
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "${KEY}" -out "${CERT}" -days 365 \
    -subj "/CN=${HOST}/O=DevOps Portfolio (laboratorio)" \
    -addext "subjectAltName=DNS:${HOST}"
elif [ ! -f "${CERT}" ] || [ ! -f "${KEY}" ]; then
  printf 'ERROR: hay un certificado o una clave sin su par en %s; no se sobrescribe.\n' "${CERT_DIR}" >&2
  exit 1
fi

chmod 600 "${KEY}"
chmod 644 "${CERT}"
if ! validate_pair; then
  printf 'ERROR: el par existente no es válido, vence pronto, no contiene SAN %s o no coincide.\n' "${HOST}" >&2
  printf 'Se conserva sin cambios. Apartalo manualmente y repetí el comando para generar otro.\n' >&2
  exit 1
fi

if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  kubectl create secret tls "${SECRET_NAME}" --namespace "${NAMESPACE}" \
    --cert="${CERT}" --key="${KEY}" --dry-run=client -o yaml | kubectl apply -f -
  printf 'Secret %s aplicado en %s.\n' "${SECRET_NAME}" "${NAMESPACE}"
else
  printf 'Par TLS validado. Namespace %s ausente: no se aplicó ningún Secret.\n' "${NAMESPACE}"
fi
