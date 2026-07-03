package com.smartkash.ledger.repository;

import com.smartkash.ledger.entity.LedgerEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LedgerEntryRepository extends JpaRepository<LedgerEntry, Long> {

    List<LedgerEntry> findByWalletIdOrderByCreatedAtDesc(Long walletId);

    List<LedgerEntry> findByTransactionReferenceOrderByCreatedAtAsc(String transactionReference);
}
