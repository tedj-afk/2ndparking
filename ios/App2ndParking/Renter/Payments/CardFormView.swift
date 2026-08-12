import SwiftUI

/// Add/edit card form with live card preview and first-digit brand detection.
/// Only Visa/Mastercard can be stored; Himyan/NAPS numbers redirect users to QPay.
struct CardFormView: View {
    enum Mode {
        case add
        case edit(PaymentCard)
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    var onSaved: ((PaymentCard) -> Void)? = nil

    @State private var holderName: String = ""
    @State private var numberText: String = ""
    @State private var expiryText: String = ""
    @State private var cvv: String = ""
    @State private var isDefault: Bool = false
    @State private var showDeleteConfirm: Bool = false

    private var editingCard: PaymentCard? {
        if case .edit(let card) = mode { return card }
        return nil
    }

    private var isEditMode: Bool { editingCard != nil }
    private var cardDigits: String { CardFormatting.digits(numberText) }
    private var detectedBrand: CardBrand? { CardBrand.detect(fromDigits: cardDigits) }
    private var isLocalDebitNumber: Bool { detectedBrand?.isLocalDebit == true }

    private var canSave: Bool {
        guard let brand = detectedBrand, !brand.isLocalDebit else { return false }
        guard holderName.trimmingCharacters(in: .whitespaces).count >= 3 else { return false }
        guard cardDigits.count == 16 else { return false }
        guard CardFormatting.validExpiry(expiryText) != nil else { return false }
        guard cvv.count == 3 || isEditMode else { return false }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 18) {
                    PaymentCardVisual(
                        brand: detectedBrand,
                        numberLine: numberText.isEmpty ? "••••  ••••  ••••  ••••" : numberText,
                        holderName: holderName,
                        expiryLabel: expiryText,
                        isDefault: isDefault
                    )

                    if isLocalDebitNumber {
                        localDebitNotice
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        formField(label: "Card Number", placeholder: "4111 2222 3333 4242", text: $numberText, keyboard: .numberPad)
                        brandRow
                    }

                    formField(label: "Cardholder Name", placeholder: "Name as printed on card", text: $holderName, keyboard: .default)

                    HStack(spacing: 12) {
                        formField(label: "Expiry", placeholder: "MM/YY", text: $expiryText, keyboard: .numberPad)
                        formField(label: "CVV", placeholder: isEditMode ? "•••" : "123", text: $cvv, keyboard: .numberPad, isSecure: true)
                    }

                    ToggleRow(label: "Set as default card", isOn: $isDefault)
                }
                .padding(16)
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: 8) {
                PrimaryButton(title: isEditMode ? "Save Changes" : "Add Card", isEnabled: canSave) {
                    save()
                }
                if isEditMode {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Card")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.failureRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Color.white)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isLocalDebitNumber)
        .onAppear(perform: prefill)
        .onChange(of: numberText) { _, newValue in
            let formatted = CardFormatting.formatNumber(newValue)
            if formatted != newValue { numberText = formatted }
        }
        .onChange(of: expiryText) { oldValue, newValue in
            // Don't reformat while deleting the slash.
            guard newValue.count > oldValue.count || !newValue.contains("/") else { return }
            let formatted = CardFormatting.formatExpiry(newValue)
            if formatted != newValue { expiryText = formatted }
        }
        .onChange(of: cvv) { _, newValue in
            let digits = String(CardFormatting.digits(newValue).prefix(3))
            if digits != newValue { cvv = digits }
        }
        .confirmationDialog("Delete this card?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Card", role: .destructive) {
                if let card = editingCard {
                    store.deletePaymentCard(id: card.id)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(editingCard?.displayName ?? "This card") will be removed from your account.")
        }
    }

    private var header: some View {
        HStack {
            Text(isEditMode ? "Edit Card" : "Add New Card")
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

    /// Brand tiles under the number field — the detected network lights up.
    private var brandRow: some View {
        HStack(spacing: 8) {
            ForEach([CardBrand.visa, .mastercard]) { brand in
                CardBrandTile(brand: brand)
                    .opacity(detectedBrand == brand ? 1 : 0.3)
                    .scaleEffect(detectedBrand == brand ? 1.06 : 1)
            }
            Spacer()
            if let brand = detectedBrand, !brand.isLocalDebit {
                Text("\(brand.rawValue) detected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.successGreen)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: detectedBrand)
    }

    private var localDebitNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color.pendingAmber)
            Text("Himyan and NAPS debit cards can't be stored. Pick \"Local Debit Card\" at checkout to pay securely through QPay.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.inkPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orangeFaint)
        .clipShape(.rect(cornerRadius: 14))
    }

    private func formField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.inkPrimary)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(.system(size: 15))
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.fieldGray)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderGray, lineWidth: 1)
            )
        }
    }

    private func prefill() {
        guard let card = editingCard, holderName.isEmpty, numberText.isEmpty else { return }
        holderName = card.holderName
        numberText = CardFormatting.formatNumber(card.number)
        expiryText = card.expiryLabel
        isDefault = card.isDefault
    }

    private func save() {
        guard let brand = detectedBrand, let expiry = CardFormatting.validExpiry(expiryText) else { return }
        let card = PaymentCard(
            id: editingCard?.id ?? UUID(),
            brand: brand,
            holderName: holderName.trimmingCharacters(in: .whitespaces),
            number: cardDigits,
            expiryMonth: expiry.month,
            expiryYear: expiry.year,
            isDefault: isDefault
        )
        if isEditMode {
            store.updatePaymentCard(card)
        } else {
            store.addPaymentCard(card)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved?(card)
        dismiss()
    }
}
