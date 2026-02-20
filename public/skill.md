# OpenLeash — skill.md

> OpenLeash is a local-first authorization and proof sidecar for AI agents. It evaluates YAML-based policies and issues PASETO v4.public cryptographic proof tokens.

## Overview

OpenLeash runs locally alongside your AI agent runtime. Before taking a side-effectful action (purchases, bookings, sending messages, government submissions), you must request authorization from OpenLeash. If approved, you receive a cryptographic proof token that counterparties can verify.

- Default server address: `http://127.0.0.1:8787`
- Protocol: HTTP/JSON
- Authentication: Ed25519 request signing
- Proof format: PASETO v4.public tokens

## Quick Start

### 1. Install and initialize

```bash
npm install @openleash/sdk-ts
npx openleash init \
  --owner-name "My Owner" \
  --agent-id "my-agent" \
  --output-env .env \
  --policy-profile balanced
npx openleash start
```

The `init` command outputs an `.env` file containing:

```
OPENLEASH_URL=http://127.0.0.1:8787
OPENLEASH_AGENT_ID=my-agent
OPENLEASH_AGENT_PRIVATE_KEY_B64=<base64-ed25519-private-key>
OPENLEASH_OWNER_PRINCIPAL_ID=<uuid>
```

### 2. Request authorization

```typescript
import { authorize } from "@openleash/sdk-ts";

const response = await authorize({
  openleashUrl: process.env.OPENLEASH_URL,
  agentId: process.env.OPENLEASH_AGENT_ID,
  privateKeyB64: process.env.OPENLEASH_AGENT_PRIVATE_KEY_B64,
  action: {
    action_id: crypto.randomUUID(),
    action_type: "payment.send",
    requested_at: new Date().toISOString(),
    principal: { agent_id: process.env.OPENLEASH_AGENT_ID },
    subject: { principal_id: process.env.OPENLEASH_OWNER_PRINCIPAL_ID },
    payload: {
      amount_minor: 5000,
      currency: "USD",
      merchant_domain: "example.com",
    },
  },
});

if (response.result === "ALLOW") {
  // Proceed with action, attach response.proof_token for counterparty verification
}
```

## TypeScript SDK (`@openleash/sdk-ts`)

```bash
npm install @openleash/sdk-ts
```

### Functions

```typescript
// Generate an Ed25519 keypair for agent registration
function generateEd25519Keypair(): {
  publicKeyB64: string;
  privateKeyB64: string;
};

// Request authorization for an action
async function authorize(params: {
  openleashUrl: string;
  agentId: string;
  privateKeyB64: string;
  action: ActionRequest;
}): Promise<AuthorizeResponse>;

// Verify a proof token against the OpenLeash server
async function verifyProofOnline(params: {
  openleashUrl: string;
  token: string;
  expectedActionHash?: string;
  expectedAgentId?: string;
}): Promise<{ valid: boolean; reason?: string; claims?: object }>;

// Verify a proof token offline using cached public keys
async function verifyProofOffline(params: {
  token: string;
  publicKeys: Array<{ kid: string; public_key_b64: string }>;
}): Promise<{ valid: boolean; reason?: string; claims?: object }>;

// Sign a request with Ed25519 (used internally by authorize)
function signRequest(params: {
  method: string;
  path: string;
  timestamp: string;
  nonce: string;
  bodyBytes: Buffer;
  privateKeyB64: string;
}): {
  "X-Timestamp": string;
  "X-Nonce": string;
  "X-Body-Sha256": string;
  "X-Signature": string;
};

// Registration challenge/response flow
async function registrationChallenge(params: {
  openleashUrl: string;
  agentId: string;
  agentPubKeyB64: string;
  ownerPrincipalId?: string;
}): Promise<{ challenge_id: string; challenge_b64: string; expires_at: string }>;

async function registerAgent(params: {
  openleashUrl: string;
  challengeId: string;
  agentId: string;
  agentPubKeyB64: string;
  signatureB64: string;
  ownerPrincipalId: string;
}): Promise<{
  agent_principal_id: string;
  agent_id: string;
  owner_principal_id: string;
  status: string;
  created_at: string;
}>;
```

## API Endpoints

### Authorization

**`POST /v1/authorize`** — Request authorization for an action.

Requires signed request headers (see Request Signing below).

Request body:

```json
{
  "action_id": "uuid",
  "action_type": "payment.send",
  "requested_at": "2026-02-20T15:30:00Z",
  "principal": { "agent_id": "my-agent" },
  "subject": { "principal_id": "owner-uuid" },
  "relying_party": {
    "domain": "example.com",
    "trust_profile": "MEDIUM"
  },
  "payload": {
    "amount_minor": 5000,
    "currency": "USD",
    "merchant_domain": "example.com"
  }
}
```

Response:

```json
{
  "decision_id": "uuid",
  "action_id": "uuid",
  "action_hash": "sha256-hex",
  "result": "ALLOW",
  "matched_rule_id": "low_amount_payments",
  "reason": "Matched rule: low_amount_payments",
  "proof_token": "v4.public.eyJ...",
  "proof_expires_at": "2026-02-20T15:35:00Z",
  "obligations": []
}
```

**Decision results:** `ALLOW`, `DENY`, `REQUIRE_APPROVAL`, `REQUIRE_STEP_UP`, `REQUIRE_DEPOSIT`

### Proof Verification

**`POST /v1/verify-proof`** — Verify a proof token (no auth required).

```json
{
  "token": "v4.public.eyJ...",
  "expected_action_hash": "hex-string",
  "expected_agent_id": "my-agent"
}
```

Response:

```json
{
  "valid": true,
  "claims": {
    "iss": "openleash",
    "kid": "uuid",
    "iat": "2026-02-20T15:30:00Z",
    "exp": "2026-02-20T15:35:00Z",
    "decision_id": "uuid",
    "owner_principal_id": "uuid",
    "agent_id": "my-agent",
    "action_type": "payment.send",
    "action_hash": "sha256-hex",
    "matched_rule_id": "low_amount_payments"
  }
}
```

### Agent Registration

**`POST /v1/agents/registration-challenge`** — Get a challenge to prove key ownership.

```json
{
  "agent_id": "my-agent",
  "agent_pubkey_b64": "base64-ed25519-public-key",
  "owner_principal_id": "uuid"
}
```

**`POST /v1/agents/register`** — Complete registration with signed challenge.

```json
{
  "challenge_id": "uuid",
  "agent_id": "my-agent",
  "agent_pubkey_b64": "base64-ed25519-public-key",
  "signature_b64": "base64-signature-over-challenge",
  "owner_principal_id": "uuid"
}
```

### Public Keys

**`GET /v1/public-keys`** — Fetch server public keys for offline proof verification.

### Health

**`GET /v1/health`** — Server health check.

## Request Signing

All agent-authenticated endpoints require Ed25519 request signing via these headers:

| Header | Value |
|---|---|
| `X-Agent-Id` | Your agent ID |
| `X-Timestamp` | ISO 8601 timestamp (must be within 120s of server time) |
| `X-Nonce` | UUID (unique per request) |
| `X-Body-Sha256` | SHA-256 hex hash of the request body |
| `X-Signature` | Base64-encoded Ed25519 signature |

Signing input format:

```
POST\n/v1/authorize\n<timestamp>\n<nonce>\n<body-sha256>
```

The SDK's `authorize()` and `signRequest()` functions handle this automatically.

## Policy Format

Policies are YAML files that define authorization rules:

```yaml
version: 1
default: deny

rules:
  - id: low_amount_payments
    effect: allow
    action: payment.send
    description: Allow payments under $100
    when:
      match:
        path: $.payload.amount_minor
        op: lte
        value: 10000
    constraints:
      currency: [USD, EUR]
      merchant_domain: [trusted.com]
    proof:
      required: true
      ttl_seconds: 300

  - id: high_value_requires_approval
    effect: allow
    action: payment.send
    when:
      match:
        path: $.payload.amount_minor
        op: gt
        value: 10000
    obligations:
      - type: HUMAN_APPROVAL
    proof:
      required: true
      ttl_seconds: 3600
```

### Rule fields

- **`action`** — Action type pattern. Exact match (`payment.send`), wildcard (`payment.*`), or catch-all (`*`).
- **`effect`** — `allow` or `deny`.
- **`when`** — Conditional expression using `match`, `all`, `any`, `not` operators. Match operators: `eq`, `neq`, `in`, `nin`, `lt`, `lte`, `gt`, `gte`, `regex`, `exists`.
- **`constraints`** — Shorthand for common limits: `amount_min`, `amount_max`, `currency`, `merchant_domain`, `allowed_domains`, `blocked_domains`.
- **`obligations`** — Required actions: `HUMAN_APPROVAL`, `STEP_UP_AUTH`, `DEPOSIT`, `COUNTERPARTY_ATTESTATION`.
- **`proof`** — Proof token settings: `required` (boolean), `ttl_seconds` (lifetime).

### Policy profiles

Use `openleash init --policy-profile <profile>` for preset policies:

- **`conservative`** — Deny by default, human approval for most actions
- **`balanced`** — Allow low-risk actions, require approval for high-value
- **`autonomous`** — Allow most actions, deny only explicitly blocked

## Error Responses

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}
```

Common codes: `INVALID_ACTION_REQUEST` (400), `INVALID_SIGNATURE` (401), `AGENT_NOT_FOUND` (401), `NO_POLICY` (403), `TIMESTAMP_SKEW` (401), `NONCE_REPLAY` (401).

## Links

- Website: https://openleash.ai
- GitHub: https://github.com/openleash/openleash
- Documentation: https://openleash.ai/docs
- npm: https://www.npmjs.com/package/@openleash/sdk-ts
- llms.txt: https://openleash.ai/llms.txt
