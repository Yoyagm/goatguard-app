#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# GoatGuard — Verificación de endpoints nuevos
# Ejecutar con: bash test_endpoints.sh
# Requisito: server (run.py + run_api.py) corriendo en localhost:8000
# ═══════════════════════════════════════════════════════════════

BASE="http://localhost:8000"
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
PASS=0
FAIL=0

# ─── Obtener JWT ──────────────────────────────────────────────
echo -e "\n${CYAN}═══ GoatGuard Endpoint Verification ═══${NC}\n"

TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}[FAIL] No se pudo obtener JWT. Verifica que el servidor esté corriendo y el usuario admin exista.${NC}"
  exit 1
fi
echo -e "${GREEN}[OK] JWT obtenido${NC}\n"

AUTH="Authorization: Bearer $TOKEN"

# ─── Helper ───────────────────────────────────────────────────
check_endpoint() {
  local method=$1
  local path=$2
  local label=$3
  local expect_type=$4  # "array" o "object"

  local response
  response=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE$path" -H "$AUTH" -H "Content-Type: application/json")
  local http_code=$(echo "$response" | tail -1)
  local body=$(echo "$response" | sed '$d')

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    echo -e "${GREEN}[PASS]${NC} ${label} — HTTP ${http_code}"

    # Mostrar resumen del body
    if [ "$expect_type" = "array" ]; then
      local count=$(echo "$body" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
      echo -e "       └─ Items: ${YELLOW}${count:-?}${NC}"
    elif [ "$expect_type" = "object" ]; then
      local keys=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(', '.join(list(d.keys())[:6]))" 2>/dev/null)
      echo -e "       └─ Keys: ${YELLOW}${keys:-?}${NC}"
    fi

    # Mostrar primeros 200 chars del body
    local preview=$(echo "$body" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin),indent=2)[:200])" 2>/dev/null)
    if [ -n "$preview" ]; then
      echo -e "       └─ Preview: ${preview}"
    fi
    echo ""
    PASS=$((PASS + 1))
  else
    echo -e "${RED}[FAIL]${NC} ${label} — HTTP ${http_code}"
    echo -e "       └─ ${body:0:150}"
    echo ""
    FAIL=$((FAIL + 1))
  fi
}

# ─── Endpoints existentes ─────────────────────────────────────
echo -e "${CYAN}── Endpoints existentes ──${NC}\n"

check_endpoint GET "/devices/"              "GET /devices/"              "array"
check_endpoint GET "/network/metrics"       "GET /network/metrics"       "object"
check_endpoint GET "/network/top-talkers/"  "GET /network/top-talkers/"  "array"
check_endpoint GET "/alerts/"               "GET /alerts/"               "array"
check_endpoint GET "/alerts/count"          "GET /alerts/count"          "object"

# ─── Nuevos endpoints ─────────────────────────────────────────
echo -e "${CYAN}── Nuevos endpoints (Sprint 8-9) ──${NC}\n"

check_endpoint GET "/dashboard/summary"              "GET /dashboard/summary"              "object"
check_endpoint GET "/network/history?hours=4"        "GET /network/history?hours=4"        "array"
check_endpoint GET "/network/isp-health"             "GET /network/isp-health"             "object"
check_endpoint GET "/network/traffic-distribution"   "GET /network/traffic-distribution"   "object"
check_endpoint GET "/devices/comparison?metric=bandwidth_in" "GET /devices/comparison"     "array"

# ─── Device-specific (usa device_id=1 si existe) ──────────────
DEVICE_ID=$(curl -s "$BASE/devices/" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d else '')" 2>/dev/null)

if [ -n "$DEVICE_ID" ]; then
  echo -e "${CYAN}── Device endpoints (device_id=$DEVICE_ID) ──${NC}\n"
  check_endpoint GET "/devices/$DEVICE_ID"              "GET /devices/$DEVICE_ID"              "object"
  check_endpoint GET "/devices/$DEVICE_ID/history?hours=4" "GET /devices/$DEVICE_ID/history"   "array"
  check_endpoint GET "/devices/$DEVICE_ID/connections"  "GET /devices/$DEVICE_ID/connections"  "array"
else
  echo -e "${YELLOW}[SKIP] No hay dispositivos registrados — skipping device-specific endpoints${NC}\n"
fi

# ─── WebSocket test ────────────────────────────────────────────
echo -e "${CYAN}── WebSocket ──${NC}\n"

WS_URL="ws://localhost:8000/ws?token=$TOKEN"
# Intentar conectar y leer 1 mensaje (timeout 8s)
WS_MSG=$(timeout 8 python3 -c "
import asyncio, websockets, json
async def test():
    async with websockets.connect('$WS_URL') as ws:
        msg = await asyncio.wait_for(ws.recv(), timeout=6)
        data = json.loads(msg)
        print(data.get('type', 'unknown'))
asyncio.run(test())
" 2>/dev/null)

if [ -n "$WS_MSG" ]; then
  echo -e "${GREEN}[PASS]${NC} WebSocket — Received message type: ${YELLOW}${WS_MSG}${NC}"
  PASS=$((PASS + 1))
else
  echo -e "${YELLOW}[WARN]${NC} WebSocket — No message received in 8s (server may need agents sending data)"
  FAIL=$((FAIL + 1))
fi

# ─── Resumen ──────────────────────────────────────────────────
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}"
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}All $TOTAL checks passed!${NC}"
else
  echo -e "${YELLOW}$FAIL/$TOTAL checks failed — review above${NC}"
fi
echo -e "${CYAN}═══════════════════════════════════════${NC}\n"
