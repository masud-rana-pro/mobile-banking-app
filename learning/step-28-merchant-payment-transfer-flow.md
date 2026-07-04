# Step 28: Merchant Payment Transfer Flow

## 1. Step Title

Step 28-এ SmartKash backend-এ Merchant Payment wallet transfer flow যোগ করা হয়েছে।

## 2. What Was Implemented

এই step-এ নতুন authenticated money-changing API যোগ করা হয়েছে:

```http
POST /api/payments/merchant
```

Request example:

```json
{
  "merchantNumber": "MRC1001",
  "amount": 75.00,
  "pin": "12345",
  "idempotencyKey": "merchant-payment-001",
  "note": "Shop payment"
}
```

Successful payment হলে backend:

- authenticated customer user খুঁজে
- customer account `ACTIVE` কিনা validate করে
- merchant number দিয়ে merchant profile খুঁজে
- merchant profile `ACTIVE` কিনা check করে
- merchant user account `ACTIVE` কিনা check করে
- customer নিজের merchant account-এ payment করছে কিনা block করে
- PIN backend-এ verify করে
- idempotency key reserve/validate করে
- customer wallet lock করে
- merchant wallet lock করে
- customer balance sufficient কিনা check করে
- customer wallet debit করে
- merchant wallet credit করে
- customer transaction record তৈরি করে
- merchant transaction record তৈরি করে
- linked debit/credit ledger entries তৈরি করে
- idempotency key completed করে

এছাড়া `GET /admin/payments` এখন merchant payment transaction records return করতে পারে।

## 3. Why This Step Is Needed

Merchant Payment SmartKash-এর payment feature-এর core backend flow। এখানে customer wallet থেকে টাকা merchant wallet-এ যায়। Merchant একটি normal user account, যার role `MERCHANT`, wallet আছে, আর business data `merchants` table-এ থাকে।

এই step ছাড়া merchant profile থাকলেও actual payment করা যেত না।

## 4. Files Created Or Changed

Created:

```text
services/backend/src/main/java/com/smartkash/payment/controller/MerchantPaymentController.java
services/backend/src/main/java/com/smartkash/payment/dto/request/MerchantPaymentRequest.java
services/backend/src/main/java/com/smartkash/payment/dto/response/MerchantPaymentResponse.java
services/backend/src/main/java/com/smartkash/payment/service/MerchantPaymentService.java
services/backend/src/main/java/com/smartkash/payment/service/impl/MerchantPaymentServiceImpl.java
learning/step-28-merchant-payment-transfer-flow.md
```

Changed:

```text
services/backend/src/main/java/com/smartkash/transaction/repository/TransactionRecordRepository.java
services/backend/src/main/java/com/smartkash/admin/service/AdminReadService.java
services/backend/src/main/java/com/smartkash/admin/service/impl/AdminReadServiceImpl.java
services/backend/src/main/java/com/smartkash/admin/controller/AdminReadController.java
docs/backend-api-plan.md
docs/security-plan.md
docs/codex-progress.md
```

## 5. Important Code Snippets

### MerchantPaymentRequest

```java
public record MerchantPaymentRequest(
        String merchantNumber,
        BigDecimal amount,
        String pin,
        String idempotencyKey,
        String note
) {
}
```

Block-by-block explanation:

- `merchantNumber`: কোন merchant-কে payment করা হবে।
- `amount`: কত টাকা customer wallet থেকে debit হবে।
- `pin`: money-changing action confirm করার জন্য backend PIN verification।
- `idempotencyKey`: duplicate payment prevent করার জন্য unique key।
- `note`: optional note, transaction description-এ যোগ হয়।

### Controller

```java
@PostMapping("/merchant")
public ResponseEntity<MerchantPaymentResponse> payMerchant(
        @AuthenticationPrincipal JwtPrincipal principal,
        @Valid @RequestBody MerchantPaymentRequest request
) {
    return ResponseEntity.ok(merchantPaymentService.payMerchant(principal, request));
}
```

Explanation:

- Base route `@RequestMapping("/api/payments")`, তাই final route `/api/payments/merchant`।
- `principal` থেকে authenticated customer identify করা হয়।
- `@Valid` request validation চালায়।
- Controller thin থাকে; business logic service layer-এ থাকে।

### Merchant Lookup And Validation

```java
Merchant merchant = merchantRepository.findByMerchantNumber(request.merchantNumber().trim())
        .orElseThrow(() -> new ResourceNotFoundException("Merchant account was not found."));
ensureActiveMerchant(merchant);

User merchantUser = merchant.getUser();
ensureActiveUser(merchantUser, "Merchant user account is not active.");
ensureNotPayingOwnMerchant(customer, merchantUser);
```

Explanation:

- `findByMerchantNumber`: merchant business number দিয়ে merchant profile খুঁজে।
- `ensureActiveMerchant`: merchant profile active না হলে payment হবে না।
- `merchant.getUser()`: merchant-ও একটি user account।
- `ensureActiveUser`: merchant user account blocked/pending হলে payment হবে না।
- `ensureNotPayingOwnMerchant`: customer নিজের merchant account-এ payment করতে পারবে না।

### PIN And Idempotency

```java
PinVerificationResponse pinVerification = authService.verifyPin(principal, new VerifyPinRequest(request.pin()));
if (!pinVerification.verified()) {
    return failedResponse("PIN verification failed.", request.amount(), merchant);
}

IdempotencyKey idempotencyKey = reserveOrValidateIdempotency(
        customer,
        request.idempotencyKey(),
        requestHash
);
```

Explanation:

- PIN backend-এ verify হয়।
- Wrong PIN হলে wallet debit/credit হয় না।
- Idempotency key একই customer-এর জন্য duplicate payment prevent করে।
- Same key দিয়ে different amount/merchant হলে error হবে।

### Wallet Debit/Credit

```java
Wallet customerWallet = walletRepository.findByUserIdForUpdate(customer.getId())
        .orElseThrow(() -> new ResourceNotFoundException("Customer wallet was not found."));
Wallet merchantWallet = walletRepository.findByUserIdForUpdate(merchantUser.getId())
        .orElseThrow(() -> new ResourceNotFoundException("Merchant wallet was not found."));

ensureSufficientBalance(customerWallet, request.amount());

BigDecimal customerBalanceAfter = customerWallet.debit(request.amount());
BigDecimal merchantBalanceAfter = merchantWallet.credit(request.amount());
```

Explanation:

- Customer wallet এবং merchant wallet দুইটাই lock করা হয়।
- Customer balance কম হলে payment বন্ধ হয়।
- `debit`: customer wallet থেকে টাকা কমায়।
- `credit`: merchant wallet-এ টাকা বাড়ায়।
- সবকিছু একই database transaction-এর মধ্যে থাকে।

### Transaction Records

```java
TransactionRecord customerTransaction = transactionRecordRepository.save(new TransactionRecord(
        customerTransactionReference,
        customer,
        TransactionType.MERCHANT_PAYMENT,
        TransactionStatus.SUCCESS,
        request.amount(),
        merchantUser,
        description
));
transactionRecordRepository.save(new TransactionRecord(
        merchantTransactionReference,
        merchantUser,
        TransactionType.MERCHANT_PAYMENT,
        TransactionStatus.SUCCESS,
        request.amount(),
        customer,
        "Merchant received payment from " + customer.getMobileNumber()
));
```

Explanation:

- Customer transaction history-তে merchant payment দেখা যাবে।
- Merchant transaction history-তেও received payment দেখা যাবে।
- দুই transaction record-এর আলাদা reference থাকে।
- `counterpartyUser` দিয়ে customer-merchant relation বোঝা যায়।

### Linked Ledger Entries

```java
LedgerEntry debitEntry = ledgerEntryRepository.save(new LedgerEntry(
        customerWallet,
        customer,
        customerTransactionReference,
        null,
        LedgerEntryType.DEBIT,
        request.amount(),
        customerBalanceAfter,
        "Merchant Payment wallet debit"
));
LedgerEntry creditEntry = ledgerEntryRepository.save(new LedgerEntry(
        merchantWallet,
        merchantUser,
        customerTransactionReference,
        debitEntry,
        LedgerEntryType.CREDIT,
        request.amount(),
        merchantBalanceAfter,
        "Merchant Payment wallet credit"
));
debitEntry.linkTo(creditEntry);
ledgerEntryRepository.save(debitEntry);
```

Explanation:

- Customer wallet-এর debit ledger entry তৈরি হয়।
- Merchant wallet-এর credit ledger entry তৈরি হয়।
- দুই ledger entry একই customer payment reference ব্যবহার করে।
- Linked entries দেখে বোঝা যায় এই debit এবং credit একই payment-এর দুই দিক।

## 6. Admin Payments Update

আগে `GET /admin/payments` empty list return করত। এখন merchant payment transaction records return করবে:

```java
return transactionRecordRepository.findByTypeOrderByCreatedAtDesc(TransactionType.MERCHANT_PAYMENT)
        .stream()
        .map(transactionRecordMapper::toResponse)
        .toList();
```

Explanation:

- Admin payments list transaction table থেকেই read করা হয়।
- শুধু `MERCHANT_PAYMENT` type filter করা হয়।
- Entity সরাসরি return না করে `TransactionResponse` DTO return করা হয়।

## 7. Expected Manual Outputs

Successful response:

```json
{
  "success": true,
  "message": "Merchant Payment completed successfully.",
  "transactionReference": "MP-ABC123...",
  "status": "SUCCESS",
  "amount": 75.00,
  "customerBalanceAfter": 875.00,
  "merchantUserId": 3,
  "merchantNumber": "MRC1001",
  "businessName": "Demo Shop",
  "createdAt": "2026-07-04T..."
}
```

Wrong PIN:

```json
{
  "success": false,
  "message": "PIN verification failed.",
  "transactionReference": null,
  "status": "FAILED"
}
```

Duplicate idempotency key with same body:

```text
Expected: no second debit, response says request was already completed.
```

Same idempotency key with different amount/merchant:

```text
Expected: 400 Bad Request
Idempotency key was already used for a different Merchant Payment request.
```

Customer paying own merchant:

```text
Expected: 400 Bad Request
Customer cannot pay their own merchant account.
```

Database expected output:

- `wallets`: customer balance decreases, merchant balance increases.
- `transactions`: `MERCHANT_PAYMENT` rows for customer and merchant.
- `ledger_entries`: linked `DEBIT` and `CREDIT` rows under the customer payment reference.
- `idempotency_keys`: `MERCHANT_PAYMENT` row with `COMPLETED` status.

## 8. How This Fits Into SmartKash Flow

Future Flutter payment flow:

1. Customer merchant number enters/scans.
2. App asks amount and PIN.
3. App sends unique idempotency key.
4. Backend validates merchant and wallets.
5. Backend moves balance from customer wallet to merchant wallet.
6. Customer and merchant both see transaction history.
7. Admin can view merchant payment records from `/admin/payments`.

## 9. Common Mistakes And Cautions

- Merchant profile active হলেই যথেষ্ট না; merchant user account and wallet active হতে হবে।
- Customer নিজের merchant account-এ payment করলে test data confusing হতে পারে, তাই blocked।
- Idempotency ছাড়া payment করলে retry/double-click duplicate debit করতে পারে।
- PIN raw value log বা database-এ রাখা যাবে না।
- Ledger entry ছাড়া wallet balance change করা যাবে না।
- Real payment gateway/provider integration করা হয়নি; zero-budget MVP rule বজায় আছে।
- Local `application-local.yml` commit করা যাবে না।

## 10. Manual Verification Commands

Backend:

```powershell
cd /d D:\github\my-kash\services\backend
.\mvnw.cmd test
.\mvnw.cmd -q -DskipTests package
.\mvnw.cmd spring-boot:run
```

Database:

```powershell
psql -h localhost -p 5432 -U smartkash_admin -d smartkash_db
SELECT id, user_id, merchant_number, business_name, status FROM merchants ORDER BY id;
SELECT id, user_id, balance, status FROM wallets ORDER BY id;
SELECT id, transaction_reference, user_id, type, status, amount, counterparty_user_id FROM transactions WHERE type = 'MERCHANT_PAYMENT' ORDER BY id DESC LIMIT 10;
SELECT id, wallet_id, user_id, transaction_reference, linked_entry_id, entry_type, amount, balance_after FROM ledger_entries ORDER BY id DESC LIMIT 10;
SELECT id, user_id, idempotency_key, operation_type, status, response_body FROM idempotency_keys ORDER BY id DESC LIMIT 10;
```

General:

```powershell
cd /d D:\github\my-kash
git status
```

## 11. Git Commands Used

```powershell
git status --short --branch
git diff --check
git add <step-28-files>
git commit -m "step-28: add merchant payment transfer flow"
git push
git status --short --branch
```

## 12. What I Learned

এই step থেকে শিখলাম merchant payment আসলে customer wallet থেকে merchant user wallet-এ একটি controlled transfer। Merchant business data আলাদা table-এ থাকলেও payment করার সময় merchant user, merchant wallet, customer wallet, PIN, idempotency, transaction record, ledger entry সব একসাথে validate করতে হয়।
