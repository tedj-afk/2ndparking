import SwiftUI

/// Multi-step ID & Residency verification wizard (mocked document capture).
struct VerificationWizardView: View {
    enum Step: Int {
        case gate = 0
        case method = 1
        case capture = 2
        case residency = 3
        case processing = 4
        case success = 5
        case failure = 6
    }

    @Environment(AppStore.self) private var store

    let onVerified: () -> Void
    let onClose: () -> Void

    @State private var step: Step = .gate
    @State private var method: String = ""
    @State private var didCapture: Bool = false
    @State private var residencyFile: String?
    @State private var attemptedOnce: Bool = false

    private var progress: Double {
        switch step {
        case .gate: return 0.15
        case .method: return 0.35
        case .capture: return 0.55
        case .residency: return 0.75
        case .processing: return 0.9
        case .success, .failure: return 1
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if step != .processing && step != .success && step != .failure {
                TopBar(leadingIcon: "xmark", onLeading: onClose)
                WizardProgressBar(progress: progress)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            switch step {
            case .gate: gateStep
            case .method: methodStep
            case .capture: captureStep
            case .residency: residencyStep
            case .processing:
                ProcessingView(
                    title: "Processing Verification",
                    message: "We're checking your documents. This usually takes a few seconds."
                )
                .task {
                    try? await Task.sleep(for: .seconds(2.2))
                    if store.simulateFailures && !attemptedOnce {
                        attemptedOnce = true
                        step = .failure
                    } else {
                        step = .success
                    }
                }
            case .success:
                ResultView(
                    isSuccess: true,
                    title: "Verification Completed",
                    message: "Your identity and residency have been verified. You can now book parking spots.",
                    primaryTitle: "Continue Booking",
                    primaryAction: onVerified
                )
            case .failure:
                ResultView(
                    isSuccess: false,
                    title: "Verification Failed",
                    message: "We couldn't verify your documents. Make sure the photos are sharp and all corners are visible, then try again.",
                    primaryTitle: "Try Again",
                    primaryAction: {
                        didCapture = false
                        residencyFile = nil
                        step = .method
                    },
                    linkTitle: "Cancel",
                    linkAction: onClose
                )
            }
        }
        .background(Color.white)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: step)
    }

    private var gateStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            Text("ID & Residency\nVerification")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .multilineTextAlignment(.center)
            Text("We need to verify your identity and residency before your first booking. You only do this once — future bookings skip this step.")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 10)

            Spacer().frame(height: 36)

            VStack(spacing: 14) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.brandOrange)
                Text("QID or Passport + proof of residency")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .background(Color.fieldGray)
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Start Verification") { step = .method }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
    }

    private var methodStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Choose your ID document")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 18)
            Text("Select the document you'll use to verify your identity")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 6)

            VStack(spacing: 12) {
                ForEach(["Qatar ID (QID)", "Passport", "GCC National ID"], id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { method = option }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: option == "Passport" ? "book.closed" : "person.text.rectangle")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.brandOrange)
                                .frame(width: 30)
                            Text(option)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.inkPrimary)
                            Spacer()
                            Image(systemName: method == option ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(method == option ? Color.brandOrange : Color.placeholderGray)
                        }
                        .padding(16)
                        .background(method == option ? Color.orangeFaint : Color.cardGray)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(method == option ? Color.brandOrange : Color.clear, lineWidth: 1.5)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)

            Spacer()

            PrimaryButton(title: "Next", isEnabled: !method.isEmpty) { step = .capture }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
    }

    private var captureStep: some View {
        VStack(spacing: 0) {
            Text("Scan your \(method.isEmpty ? "document" : method)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.top, 18)
            Text("Position the front side inside the frame")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .padding(.top, 6)

            Spacer().frame(height: 28)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.inkPrimary.opacity(0.9))
                if didCapture {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.successGreen)
                        Text("Document captured")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                } else {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            .frame(width: 250, height: 150)
                            .overlay(
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white.opacity(0.5))
                            )
                        Text("Camera preview (mock)")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 320)
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(title: didCapture ? "Next" : "Capture") {
                if didCapture {
                    step = .residency
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { didCapture = true }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }

    private var residencyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Proof of residency")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.inkPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 18)
            Text("Upload a utility bill or tenancy contract showing your name and address")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 6)

            UploadDropzone(
                helper: "Upload document (PDF or photo)",
                mockFileName: "tenancy_contract.pdf",
                uploadedFile: $residencyFile
            )
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()

            PrimaryButton(title: "Submit for Verification", isEnabled: residencyFile != nil) {
                step = .processing
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }
}
