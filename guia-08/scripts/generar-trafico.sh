#!/bin/bash
echo "Generando tráfico durante 2 minutos..."
for i in $(seq 1 120); do
    curl -s http://localhost/api/notes > /dev/null
    curl -s http://localhost/health > /dev/null
    if [ $((i % 10)) -eq 0 ]; then
        curl -s -X POST http://localhost/api/notes \
          -H "Content-Type: application/json" \
          -d "{\"title\": \"Nota $i\", \"content\": \"Generada automáticamente\"}" \
          > /dev/null
    fi
    sleep 1
    echo -ne "  Request $i/120\r"
done
echo "Tráfico generado."
