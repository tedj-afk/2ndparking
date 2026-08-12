import SwiftUI

/// Full-sheet flow for adding a vehicle (used from Review & Pay).
struct AddVehicleView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Called with the newly saved vehicle so the caller can select it.
    var onSaved: (Vehicle) -> Void

    @State private var brand: String = ""
    @State private var customBrand: String = ""
    @State private var model: String = ""
    @State private var plate: String = ""

    private let brands = [
        "Toyota", "Nissan", "Land Rover", "Lexus", "BMW", "Mercedes-Benz",
        "Audi", "Volkswagen", "Hyundai", "Kia", "Jetour", "Tesla", "Other"
    ]

    private var resolvedBrand: String {
        brand == "Other" ? customBrand : brand
    }

    private var canSave: Bool {
        !resolvedBrand.isEmpty && !model.isEmpty && !plate.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                CircleIconButton(systemName: "xmark") { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Vehicle")
                            .font(.pageTitle)
                            .foregroundStyle(Color.inkPrimary)
                        Text("Security uses these details to recognize your car at the gate.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.inkSecondary)
                    }

                    DropdownField(label: "Brand", placeholder: "Select brand", options: brands, selection: $brand)

                    if brand == "Other" {
                        FormField(label: "Brand Name", placeholder: "e.g., Chery", text: $customBrand)
                    }

                    FormField(label: "Model", placeholder: "e.g., Land Cruiser", text: $model)

                    FormField(label: "Plate Number", placeholder: "e.g., A10232", text: $plate)

                    if canSave {
                        HStack(spacing: 12) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.brandOrange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(resolvedBrand) \(model)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.inkPrimary)
                                Text(plate.uppercased())
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.inkSecondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.orangeFaint)
                        .clipShape(.rect(cornerRadius: 14))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: canSave)

            PrimaryButton(title: "Save Vehicle", isEnabled: canSave) {
                let vehicle = Vehicle(
                    id: UUID(),
                    brand: resolvedBrand,
                    model: model,
                    plate: plate.uppercased()
                )
                store.addVehicle(vehicle)
                onSaved(vehicle)
                dismiss()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }
}
