import Foundation

/// Seed data for the click-through prototype. All content is Qatar-localized.
enum MockData {
    static let defaultInstructions: [String] = [
        "Drive to the building's main entrance on the visitor lane.",
        "Show your Access Pass QR code to the security officer.",
        "Follow the ramp down to the indicated basement level.",
        "Park only in your assigned spot number.",
        "Check-out with security when leaving the facility."
    ]

    static let defaultPolicy = "Cancel free of charge up to 1 hour before the start time. Later cancellations are charged 50% of the total price."

    // MARK: - Seed availability schedules

    /// Open every day from 6 AM to midnight.
    static let pearlSchedule: AvailabilitySchedule = {
        var schedule = AvailabilitySchedule()
        schedule.windows = Weekday.allCases.map { _ in
            AvailabilitySchedule.DayWindow(isOpen: true, openMinutes: 6 * 60, closeMinutes: 24 * 60)
        }
        schedule.maxNights = 14
        return schedule
    }()

    /// Work-hours spot with a longer window and two personal days blocked off.
    static let marinaSchedule: AvailabilitySchedule = {
        var schedule = AvailabilitySchedule.workHours(open: 7 * 60 + 30, close: 18 * 60)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for offset in [3, 4] {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                schedule.blockedDates.insert(date)
            }
        }
        schedule.maxNights = 3
        return schedule
    }()

    /// Long-stay spot: full days only, minimum three nights.
    static let msheirebSchedule: AvailabilitySchedule = {
        var schedule = AvailabilitySchedule()
        schedule.allowsHourly = false
        schedule.minNights = 3
        schedule.maxNights = 30
        return schedule
    }()

    static let spots: [ParkingSpot] = [
        ParkingSpot(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
            spotCode: "P2-032",
            buildingName: "LIV Residence",
            address: "LIV Residence, Diplomatic Street, West Bay, Doha, Qatar",
            level: "Basement 2",
            accessType: "Check-in with Security",
            maxVehicleHeight: "Up to 2.2m height",
            schedule: .workHours(),
            hasChargingStation: true,
            securityType: "CCTV monitored",
            description: "Covered spot on Level B2 near the elevator. Suitable for sedans and SUVs. Easy to enter and exit.",
            photos: ["underground_parking_garage", "ev_charging_garage", "parking_deck_residential", "parking_garage_basement", "underground_parking_garage"],
            pricePerHour: 10,
            pricePerDay: 60,
            rating: 4.5,
            reviewCount: 7,
            listerName: "Ahmed Fadi",
            listerVerified: true,
            status: .reserved,
            accessInstructions: defaultInstructions,
            cancellationPolicy: defaultPolicy,
            latitude: 25.3319, longitude: 51.5288
        ),
        ParkingSpot(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!,
            spotCode: "P4-100",
            buildingName: "LIV Residence",
            address: "LIV Residence, Diplomatic Street, West Bay, Doha, Qatar",
            level: "Basement 4",
            accessType: "Check-in with Security",
            maxVehicleHeight: "Up to 2.2m height",
            schedule: .alwaysOpen,
            hasChargingStation: false,
            securityType: "CCTV monitored",
            description: "Secure parking spot in a covered garage with 24/7 building access. Easy location, close to the elevators, suitable for long-term parking.",
            photos: ["parking_garage_basement", "underground_parking_garage", "ev_charging_garage", "parking_deck_residential", "parking_garage_basement"],
            pricePerHour: 9,
            pricePerDay: 55,
            rating: 4.5,
            reviewCount: 43,
            listerName: "James",
            listerVerified: true,
            status: .live,
            accessInstructions: defaultInstructions,
            cancellationPolicy: defaultPolicy,
            latitude: 25.3319, longitude: 51.5288,
            supportsMonthly: true
        ),
        ParkingSpot(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!,
            spotCode: "B1-014",
            buildingName: "Darwish Tower",
            address: "Darwish Tower, Porto Arabia, The Pearl, Doha, Qatar",
            level: "Basement 1",
            accessType: "Remote gate",
            maxVehicleHeight: "Up to 2.0m height",
            schedule: MockData.pearlSchedule,
            hasChargingStation: false,
            securityType: "CCTV monitored",
            description: "Bright spot right next to the B1 ramp. Perfect for compact cars and quick visits to The Pearl boardwalk.",
            photos: ["ev_charging_garage", "parking_deck_residential", "underground_parking_garage"],
            pricePerHour: 8,
            pricePerDay: 50,
            rating: 4.8,
            reviewCount: 12,
            listerName: "Mariam Al-Sulaiti",
            listerVerified: true,
            status: .live,
            accessInstructions: defaultInstructions,
            cancellationPolicy: defaultPolicy,
            latitude: 25.3697, longitude: 51.5445
        ),
        ParkingSpot(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000004")!,
            spotCode: "P1-201",
            buildingName: "Forty Four West Bay Tower",
            address: "Forty Four Tower, Al Funduq Street, West Bay, Doha, Qatar",
            level: "Podium 1",
            accessType: "Key handover",
            maxVehicleHeight: "Up to 2.4m height",
            schedule: .preset(.evenings),
            hasChargingStation: true,
            securityType: "Guard on site",
            description: "Extra-wide podium spot with EV charger. Fits large SUVs comfortably, two steps from the lobby lifts.",
            photos: ["parking_deck_residential", "parking_garage_basement", "ev_charging_garage"],
            pricePerHour: 11,
            pricePerDay: 55,
            rating: 4.2,
            reviewCount: 9,
            listerName: "Yousef Al-Kuwari",
            listerVerified: false,
            status: .free,
            accessInstructions: defaultInstructions,
            cancellationPolicy: defaultPolicy,
            latitude: 25.3247, longitude: 51.5300,
            supportsMonthly: true
        ),
        ParkingSpot(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000005")!,
            spotCode: "G-08",
            buildingName: "Marina Twin Tower",
            address: "Marina Twin Tower, Marina District, Lusail, Doha, Qatar",
            level: "Ground",
            accessType: "Check-in with Security",
            maxVehicleHeight: "No height limit",
            schedule: MockData.marinaSchedule,
            hasChargingStation: false,
            securityType: "CCTV monitored",
            description: "Shaded ground-level spot by the marina promenade. Drive in and out in seconds — no ramps.",
            photos: ["underground_parking_garage", "parking_deck_residential", "parking_garage_basement"],
            pricePerHour: 12,
            pricePerDay: 70,
            rating: 4.9,
            reviewCount: 21,
            listerName: "Noora Al-Thani",
            listerVerified: true,
            status: .live,
            accessInstructions: defaultInstructions,
            cancellationPolicy: defaultPolicy,
            latitude: 25.3785, longitude: 51.5250
        ),
        ParkingSpot(
            id: UUID(uuidString: "A1000000-0000-0000-0000-000000000006")!,
            spotCode: "P3-077",
            buildingName: "Al Jazi Gardens",
            address: "Al Jazi Gardens, Msheireb Downtown, Doha, Qatar",
            level: "Basement 3",
            accessType: "Check-in with Security",
            maxVehicleHeight: "Up to 2.1m height",
            schedule: MockData.msheirebSchedule,
            hasChargingStation: false,
            securityType: "CCTV monitored",
            description: "Quiet long-term spot in Msheireb. Ideal for commuters working downtown.",
            photos: ["parking_garage_basement", "ev_charging_garage", "underground_parking_garage"],
            pricePerHour: nil,
            pricePerDay: 45,
            rating: 4.6,
            reviewCount: 15,
            listerName: "Khalid Rahimi",
            listerVerified: true,
            status: .archived,
            accessInstructions: defaultInstructions,
            cancellationPolicy: defaultPolicy,
            latitude: 25.2854, longitude: 51.5260,
            supportsMonthly: true
        )
    ]

    static let vehicles: [Vehicle] = [
        Vehicle(id: UUID(), brand: "Volkswagen", model: "Passat", plate: "A10232"),
        Vehicle(id: UUID(), brand: "Jetour", model: "X70 Plus", plate: "B33421")
    ]

    static let paymentCards: [PaymentCard] = [
        PaymentCard(
            id: UUID(uuidString: "C1000000-0000-0000-0000-000000000001")!,
            brand: .visa, holderName: "Nacer Lalaoui",
            number: "4111222233334242", expiryMonth: 8, expiryYear: 2027, isDefault: true
        ),
        PaymentCard(
            id: UUID(uuidString: "C1000000-0000-0000-0000-000000000002")!,
            brand: .mastercard, holderName: "Nacer Lalaoui",
            number: "5200334455668810", expiryMonth: 11, expiryYear: 2026, isDefault: false
        )
    ]

    static func seedReservations() -> [Reservation] {
        let liv = spots[0]
        let livB4 = spots[1]
        let pearl = spots[2]
        let marina = spots[4]
        let msheireb = spots[5]
        return [
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000001")!,
                spot: liv, duration: .hourly,
                dateLabel: "Today", endDateLabel: nil,
                startTime: "11:00 AM", endTime: "03:00 PM",
                totalPrice: 40, status: .active, stage: .completed,
                vehicleBrand: "Volkswagen", vehicleModel: "Passat", plateNumber: "A10232",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Ahmed Fadi", unitNumber: "402", countdown: "3:59",
                payment: PaymentRecord(method: .applePay, amount: 40, paidAtLabel: "Today, 10:48 AM", reference: "2P-7C41A9E2"),
                checkedInAtLabel: "11:07 AM"
            ),
            // Still inside past the booked window — overstay case for security.
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000009")!,
                spot: marina, duration: .hourly,
                dateLabel: "Today", endDateLabel: nil,
                startTime: "08:00 AM", endTime: "11:00 AM",
                totalPrice: 36, status: .active, stage: .completed,
                vehicleBrand: "Jetour", vehicleModel: "X70 Plus", plateNumber: "B33421",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Noora Al-Thani", unitNumber: "705", countdown: nil,
                payment: PaymentRecord(method: .card(.mastercard, last4: "8810"), amount: 36, paidAtLabel: "Today, 7:41 AM", reference: "2P-4A17E9C3"),
                checkedInAtLabel: "08:04 AM",
                overstayMinutes: 47
            ),
            // Window already started, car never showed up — late arrival case.
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000010")!,
                spot: pearl, duration: .hourly,
                dateLabel: "Today", endDateLabel: nil,
                startTime: "09:30 AM", endTime: "12:30 PM",
                totalPrice: 24, status: .upcoming, stage: .completed,
                vehicleBrand: "Volkswagen", vehicleModel: "Passat", plateNumber: "A10232",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Mariam Al-Sulaiti", unitNumber: "1108", countdown: nil,
                payment: PaymentRecord(method: .applePay, amount: 24, paidAtLabel: "Today, 8:12 AM", reference: "2P-6B92D40F"),
                lateArrivalMinutes: 22
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000002")!,
                spot: liv, duration: .hourly,
                dateLabel: "04/12/2026", endDateLabel: nil,
                startTime: "11:00 AM", endTime: "03:00 PM",
                totalPrice: 40, status: .upcoming, stage: .completed,
                vehicleBrand: "Volkswagen", vehicleModel: "Passat", plateNumber: "A10232",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Ahmed Fadi", unitNumber: "402", countdown: nil,
                payment: PaymentRecord(method: .card(.visa, last4: "4242"), amount: 40, paidAtLabel: "28 Nov, 6:12 PM", reference: "2P-3F8B2D51")
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000003")!,
                spot: pearl, duration: .daily,
                dateLabel: "Dec 06th", endDateLabel: "Dec 08th",
                startTime: nil, endTime: nil,
                totalPrice: 150, status: .upcoming, stage: .completed,
                vehicleBrand: "Jetour", vehicleModel: "X70 Plus", plateNumber: "B33421",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Mariam Al-Sulaiti", unitNumber: "1108", countdown: nil,
                payment: PaymentRecord(method: .qpay, amount: 150, paidAtLabel: "25 Nov, 9:04 AM", reference: "2P-9D02C7A4")
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000004")!,
                spot: livB4, duration: .daily,
                dateLabel: "Dec 1st", endDateLabel: "Dec 15th",
                startTime: nil, endTime: nil,
                totalPrice: 770, status: .pending, stage: .requested,
                vehicleBrand: "Volkswagen", vehicleModel: "Passat", plateNumber: "A10232",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "James", unitNumber: "2203", countdown: nil
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000005")!,
                spot: msheireb, duration: .daily,
                dateLabel: "Jan 2nd", endDateLabel: "Jan 12th",
                startTime: nil, endTime: nil,
                totalPrice: 450, status: .pending, stage: .payDeposit,
                vehicleBrand: "Jetour", vehicleModel: "X70 Plus", plateNumber: "B33421",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Khalid Rahimi", unitNumber: "310", countdown: nil
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000006")!,
                spot: liv, duration: .hourly,
                dateLabel: "22/11/2026", endDateLabel: nil,
                startTime: "09:00 AM", endTime: "01:00 PM",
                totalPrice: 40, status: .past, stage: .completed,
                vehicleBrand: "Volkswagen", vehicleModel: "Passat", plateNumber: "A10232",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Ahmed Fadi", unitNumber: "402", countdown: nil,
                payment: PaymentRecord(method: .card(.visa, last4: "4242"), amount: 40, paidAtLabel: "22 Nov, 8:41 AM", reference: "2P-1E6F0B83"),
                checkedInAtLabel: "08:56 AM",
                checkedOutAtLabel: "01:18 PM",
                overstayMinutes: 18
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000007")!,
                spot: pearl, duration: .daily,
                dateLabel: "Oct 12th", endDateLabel: "Oct 14th",
                startTime: nil, endTime: nil,
                totalPrice: 100, status: .past, stage: .completed,
                vehicleBrand: "Jetour", vehicleModel: "X70 Plus", plateNumber: "B33421",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "Mariam Al-Sulaiti", unitNumber: "1108", countdown: nil,
                payment: PaymentRecord(method: .applePay, amount: 100, paidAtLabel: "12 Oct, 3:20 PM", reference: "2P-5A9C4E17"),
                checkedInAtLabel: "09:12 AM",
                checkedOutAtLabel: "05:46 PM"
            ),
            Reservation(
                id: UUID(uuidString: "B1000000-0000-0000-0000-000000000008")!,
                spot: livB4, duration: .hourly,
                dateLabel: "18/10/2026", endDateLabel: nil,
                startTime: "02:00 PM", endTime: "06:00 PM",
                totalPrice: 40, status: .cancelled, stage: .completed,
                vehicleBrand: "Volkswagen", vehicleModel: "Passat", plateNumber: "A10232",
                guestName: "Nacer Lalaoui", guestPhone: "+974 5583 3202",
                residentName: "James", unitNumber: "2203", countdown: nil,
                payment: PaymentRecord(method: .card(.mastercard, last4: "8810"), amount: 40, paidAtLabel: "16 Oct, 11:55 AM", reference: "2P-8B3D6F29")
            )
        ]
    }

    /// Seeded reservation IDs used to deep-link notifications to reservation details.
    private static func reservationID(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "B1000000-0000-0000-0000-%012d", index))!
    }

    static let renterNotifications: [AppNotification] = [
        AppNotification(id: UUID(), title: "Request Accepted", message: "James accepted your long-term request for P4-100. Pay the deposit to continue.", timeAgo: "1 min", isUnread: true, tint: .orange, icon: "checkmark.seal.fill", reservationID: reservationID(4)),
        AppNotification(id: UUID(), title: "Reservation starting soon", message: "Your reservation at LIV Residence starts in 30 minutes.", timeAgo: "28 min", isUnread: true, tint: .blue, icon: "clock.fill", reservationID: reservationID(2)),
        AppNotification(id: UUID(), title: "Payment received", message: "We received your payment of 40 QAR for P2-032.", timeAgo: "2 h", isUnread: false, tint: .green, icon: "banknote.fill", reservationID: reservationID(1)),
        AppNotification(id: UUID(), title: "Rate your stay", message: "How was parking at Darwish Tower? Leave a quick rating.", timeAgo: "1 d", isUnread: false, tint: .blue, icon: "star.fill", reservationID: reservationID(7)),
        AppNotification(id: UUID(), title: "Verification completed", message: "Your QID and residency documents were verified successfully.", timeAgo: "3 d", isUnread: false, tint: .green, icon: "checkmark.shield.fill")
    ]

    static let listerNotifications: [AppNotification] = [
        AppNotification(id: UUID(), title: "New Request", message: "request from Jake just came in!", timeAgo: "1 min", isUnread: true, tint: .orange, icon: "envelope.badge.fill", opensRequest: true),
        AppNotification(id: UUID(), title: "Rental has just started", message: "Nacer's long-term rental of P4-100 started today.", timeAgo: "1 min", isUnread: true, tint: .orange, icon: "car.fill", reservationID: reservationID(4)),
        AppNotification(id: UUID(), title: "Rental finished", message: "The long-term rental of P3-077 has ended.", timeAgo: "2 h", isUnread: false, tint: .blue, icon: "flag.checkered", reservationID: reservationID(5)),
        AppNotification(id: UUID(), title: "Rental finished", message: "The long-term rental of B2-024 has ended.", timeAgo: "1 d", isUnread: false, tint: .blue, icon: "flag.checkered"),
        AppNotification(id: UUID(), title: "Payment received!", message: "630 QAR payout is on its way to your bank account.", timeAgo: "2 d", isUnread: false, tint: .green, icon: "banknote.fill")
    ]

    static let securityNotifications: [AppNotification] = [
        AppNotification(id: UUID(), title: "Guest checked in", message: "Nacer Lalaoui checked in to P2-032 at 11:07 AM.", timeAgo: "5 min", isUnread: true, tint: .green, icon: "person.crop.circle.badge.checkmark", reservationID: reservationID(1)),
        AppNotification(id: UUID(), title: "Upcoming arrival", message: "Guest expected at P4-100 between 11:00 AM and 3:00 PM.", timeAgo: "1 h", isUnread: false, tint: .blue, icon: "car.fill", reservationID: reservationID(2)),
        AppNotification(id: UUID(), title: "Overstay alert", message: "B33421 at G-08 is 47 min past its booked check-out. Charge the overstay fee at the gate.", timeAgo: "2 min", isUnread: true, tint: .orange, icon: "exclamationmark.triangle.fill", reservationID: reservationID(9)),
        AppNotification(id: UUID(), title: "Guest running late", message: "A10232 was expected at B1-014 at 9:30 AM. The spot stays reserved.", timeAgo: "22 min", isUnread: true, tint: .blue, icon: "clock.badge.exclamationmark.fill", reservationID: reservationID(10)),
        AppNotification(id: UUID(), title: "Check-out reminder", message: "P2-32 reservation ends at 3:00 PM today.", timeAgo: "2 h", isUnread: false, tint: .orange, icon: "clock.badge.exclamationmark.fill", reservationID: reservationID(1))
    ]

    static let payouts: [Payout] = [
        Payout(id: UUID(), dateLabel: "01/08/2026", amount: 598.50, status: "Paid"),
        Payout(id: UUID(), dateLabel: "01/07/2026", amount: 598.50, status: "Paid"),
        Payout(id: UUID(), dateLabel: "01/06/2026", amount: 342.00, status: "Paid")
    ]
}
