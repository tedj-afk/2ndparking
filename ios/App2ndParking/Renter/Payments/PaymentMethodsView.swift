import SwiftUI

/// Wallet screen: manage stored Visa/Mastercard cards — set default, edit, delete, add.
struct PaymentMethodsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var editingCard: PaymentCard?
    @State private var showAddCard: Bool = false
    @State private var cardPendingDelete: PaymentCard?

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { cardPendingDelete != nil },
            set: { if !$0 { cardPendingDelete = nil } }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    if store.paymentCards.isEmpty {
                        emptyState
                    }

                    ForEach(store.paymentCards) { card in
                        cardSection(card)
                    }

                    walletNote
                }
                .padding(16)
                .padding(.bottom, 12)
            }

            PrimaryButton(title: "Add New Card") {
                showAddCard = true
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color.white)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.paymentCards)
        .sheet(item: $editingCard) { card in
            CardFormView(mode: .edit(card))
        }
        .sheet(isPresented: $showAddCard) {
            CardFormView(mode: .add)
        }
        .confirmationDialog("Delete this card?", isPresented: deleteDialogBinding, titleVisibility: .visible) {
            Button("Delete Card", role: .destructive) {
                if let card = cardPendingDelete {
                    store.deletePaymentCard(id: card.id)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                cardPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { cardPendingDelete = nil }
        } message: {
            Text("\(cardPendingDelete?.displayName ?? "This card") will be removed from your account.")
        }
    }

    private var header: some View {
        HStack {
            Text("Payment Methods")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.fieldGray)
                    .clipShape(.circle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func cardSection(_ card: PaymentCard) -> some View {
        VStack(spacing: 10) {
            Button { editingCard = card } label: {
                PaymentCardVisual(
                    brand: card.brand,
                    numberLine: "••••  ••••  ••••  \(card.last4)",
                    holderName: card.holderName,
                    expiryLabel: card.expiryLabel,
                    isDefault: card.isDefault
                )
            }
            .buttonStyle(.plain)

            if card.isExpired {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.failureRed)
                    Text("This card has expired — update the expiry date.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.failureRed)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            HStack(spacing: 8) {
                if !card.isDefault {
                    actionChip(title: "Set as Default", icon: "star") {
                        store.setDefaultPaymentCard(id: card.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                actionChip(title: "Edit", icon: "pencil") {
                    editingCard = card
                }
                actionChip(title: "Delete", icon: "trash", tint: .failureRed) {
                    cardPendingDelete = card
                }
                Spacer()
            }
        }
    }

    private func actionChip(title: String, icon: String, tint: Color = .inkPrimary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(Color.cardGray)
            .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "creditcard")
                .font(.system(size: 34))
                .foregroundStyle(Color.inkTertiary)
            Text("No saved cards")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
            Text("Add a Visa or Mastercard to check out faster.")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.cardGray)
        .clipShape(.rect(cornerRadius: 18))
    }

    private var walletNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.infoBlue)
            Text("Apple Pay and local debit cards (Himyan · NAPS via QPay) are always available at checkout — no setup needed.")
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.infoPale.opacity(0.5))
        .clipShape(.rect(cornerRadius: 14))
    }
}
