 FreelanceTrustVault

**FreelanceTrustVault** is a Clarity smart contract for the Stacks blockchain that enables milestone-based freelance payments through escrow, with added trust-building features like ratings and feedback. It ensures secure, transparent transactions between clients and freelancers.

---

 Features

-  **Escrow Creation**: Clients initiate milestone-based escrows for freelancers.
-  **Secure Payments**: Funds are locked until client or admin approves release.
-  **Escrow Expiry**: Automatically handles deadline and expiry conditions.
-  **Client Refunds**: Admins can process refunds in case of dispute or expiration.
-  **Freelancer Ratings**: Clients can rate freelancers after payout.
-  **Feedback System**: Clients can submit feedback text for accountability.
-  **Read-Only Queries**: Check escrow status and latest transaction ID.

---

 How It Works

1. **Client** creates an escrow by specifying a freelancer, total funds, and milestone amount.
2. Funds are locked in the contract for a predefined duration (~7 days).
3. Upon milestone completion:
   - The client or admin releases funds to the freelancer.
   - The client may leave a rating and feedback.
4. If the deadline passes without action, an admin may refund the client.

---

 Smart Contract Structure

| Component              | Purpose                                |
|------------------------|----------------------------------------|
| `EscrowRecords`        | Stores active escrow transactions      |
| `initialize-milestone-escrow` | Starts a new escrow               |
| `execute-milestone-payout`    | Releases funds to freelancer       |
| `process-client-refund`       | Refunds client via admin           |
| `submit-rating`              | Allows client to rate freelancer   |
| `submit-feedback`            | Allows client to write feedback    |
| `fetch-escrow-info`         | Read-only: fetch escrow details    |
| `fetch-latest-transaction-id` | Read-only: get latest escrow ID   |

---

 Security and Permissions

- **Only clients** can create escrows and submit ratings/feedback.
- **Admins** can override and refund funds in case of failure or disputes.
- **Freelancers** must be different from the contract sender (no self-dealing).

---

 Deployment

To deploy using [Clarinet](https://docs.stacks.co/write-smart-contracts/clarinet/intro):

```bash
clarinet check
clarinet test
clarinet deploy
