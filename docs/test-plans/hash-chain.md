# Test plan: hash chain

Status: pending Q1.

| ID | Case | Expected |
|---|---|---|
| H-01 | First initial record, empty previous fingerprint | Official AEAT vector 1 |
| H-02 | Initial record chained to H-01 | Official AEAT vector 2 |
| H-03 | Cancellation record chained to H-02 | Official AEAT vector 3 |
| H-04 | Amount with two decimals and with trailing zero | Format as in official spec |
| H-05 | Date and timezone offset in generation timestamp | Format as in official spec |
| H-06 | Modify one stored field of record N | Verification fails starting at N |
| H-07 | Delete a record from the middle of the chain | Verification detects the gap |
| H-08 | Leading and trailing spaces in a field | Trimmed before concatenation |

Vectors H-01 to H-03 are filled from the official AEAT document once it is verified.
