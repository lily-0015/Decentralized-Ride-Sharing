module ride_sharing::ride_sharing {
    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Option, none, some, is_some, contains, borrow};
    use std::vector;

    // Errors
    const EInvalidBid: u64 = 1;
    const EInvalidRide: u64 = 2;
    const EDispute: u64 = 3;
    const EAlreadyResolved: u64 = 4;
    const ENotDriver: u64 = 5;
    const EInvalidWithdrawal: u64 = 7;
    const EInvalidRating: u64 = 8;
    const ENotRider: u64 = 9;
    const EInsufficientFunds: u64 = 10;

    // Struct definitions
    struct Ride has key, store {
        id: UID,
        rider: address,
        driver: Option<address>,
        destination: vector<u8>,
        price: u64,
        escrow: Balance<SUI>,
        rideCompleted: bool,
        dispute: bool,
        riderRating: Option<u8>, // Rating given by the rider (0-5)
        driverRating: Option<u8>, // Rating given by the driver (0-5)
    }

    // Accessors
    public entry fun get_ride_destination(ride: &Ride): vector<u8> {
        ride.destination
    }

    public entry fun get_ride_price(ride: &Ride): u64 {
        ride.price
    }

    // Public - Entry functions
    public entry fun request_ride(destination: vector<u8>, price: u64, ctx: &mut TxContext) {
        assert!(price > 0, EInvalidRide);

        let ride_id = object::new(ctx);
        transfer::share_object(Ride {
            id: ride_id,
            rider: tx_context::sender(ctx),
            driver: none(),
            destination: destination,
            price: price,
            escrow: balance::zero(),
            rideCompleted: false,
            dispute: false,
            riderRating: none(),
            driverRating: none(),
        });
    }

    public entry fun accept_ride(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(!is_some(&ride.driver), EInvalidBid);
        ride.driver = some(tx_context::sender(ctx));
    }

    public entry fun complete_ride(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(contains(&ride.driver, &tx_context::sender(ctx)), ENotDriver);
        ride.rideCompleted = true;
    }

    public entry fun dispute_ride(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx), EDispute);
        ride.dispute = true;
    }

    public entry fun resolve_dispute(ride: &mut Ride, resolved: bool, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx), EDispute);
        assert!(ride.dispute, EAlreadyResolved);
        assert!(is_some(&ride.driver), EInvalidBid);
        let escrow_amount = balance::value(&ride.escrow);
        let escrow_coin = coin::take(&mut ride.escrow, escrow_amount, ctx);
        if (resolved) {
            let driver = *borrow(&ride.driver);
            // Transfer funds to the driver
            transfer::public_transfer(escrow_coin, driver);
        } else {
            // Refund funds to the rider
            transfer::public_transfer(escrow_coin, ride.rider);
        };

        // Reset ride state
        ride.driver = none();
        ride.rideCompleted = false;
        ride.dispute = false;
    }

    public entry fun release_payment(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx), ENotRider);
        assert!(ride.rideCompleted && !ride.dispute, EInvalidRide);
        assert!(is_some(&ride.driver), EInvalidBid);
        let driver = *borrow(&ride.driver);
        let escrow_amount = balance::value(&ride.escrow);
        let escrow_coin = coin::take(&mut ride.escrow, escrow_amount, ctx);
        // Transfer funds to the driver
        transfer::public_transfer(escrow_coin, driver);

        // Reset ride state
        ride.driver = none();
        ride.rideCompleted = false;
        ride.dispute = false;
    }

    // Additional functions
    public entry fun cancel_ride(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx) || contains(&ride.driver, &tx_context::sender(ctx)), ENotDriver);

        // Refund funds to the rider if not yet paid
        if (is_some(&ride.driver) && !ride.rideCompleted && !ride.dispute) {
            let escrow_amount = balance::value(&ride.escrow);
            let escrow_coin = coin::take(&mut ride.escrow, escrow_amount, ctx);
            transfer::public_transfer(escrow_coin, ride.rider);
        };

        // Reset ride state
        ride.driver = none();
        ride.rideCompleted = false;
        ride.dispute = false;
    }

    public entry fun update_ride_destination(ride: &mut Ride, new_destination: vector<u8>, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx), ENotRider);
        assert!(!ride.rideCompleted, EInvalidRide); // Only allow updating destination before ride completion
        ride.destination = new_destination;
    }

    public entry fun update_ride_price(ride: &mut Ride, new_price: u64, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx), ENotRider);
        assert!(!ride.rideCompleted, EInvalidRide); // Only allow updating price before ride completion
        assert!(new_price > 0, EInvalidRide);
        ride.price = new_price;
    }

    // New functions
    public entry fun add_funds_to_ride(ride: &mut Ride, amount: Coin<SUI>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == ride.rider, ENotRider);
        assert!(!ride.rideCompleted && !ride.dispute, EInvalidWithdrawal);
        let added_balance = coin::into_balance(amount);
        balance::join(&mut ride.escrow, added_balance);
    }

    public entry fun request_refund(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == ride.rider, ENotRider);
        assert!(ride.rideCompleted == false, EInvalidWithdrawal);
        let escrow_amount = balance::value(&ride.escrow);
        let escrow_coin = coin::take(&mut ride.escrow, escrow_amount, ctx);
        // Refund funds to the rider
        transfer::public_transfer(escrow_coin, ride.rider);

        // Reset ride state
        ride.driver = none();
        ride.rideCompleted = false;
        ride.dispute = false;
    }

    public entry fun mark_ride_complete(ride: &mut Ride, ctx: &mut TxContext) {
        assert!(contains(&ride.driver, &tx_context::sender(ctx)), ENotDriver);
        assert!(balance::value(&ride.escrow) >= ride.price, EInsufficientFunds);
        ride.rideCompleted = true;
    }

    public entry fun rateDriver(ride: &mut Ride, rating: u8, ctx: &mut TxContext) {
        assert!(ride.rider == tx_context::sender(ctx), ENotRider);
        assert!(ride.rideCompleted && !ride.dispute, EInvalidRide);
        assert!(rating >= 0 && rating <= 5, EInvalidRating);
        ride.driverRating = some(rating);
    }

    public entry fun rateRider(ride: &mut Ride, rating: u8, ctx: &mut TxContext) {
        assert!(contains(&ride.driver, &tx_context::sender(ctx)), ENotDriver);
        assert!(ride.rideCompleted && !ride.dispute, EInvalidRide);
        assert!(rating >= 0 && rating <= 5, EInvalidRating);
        ride.riderRating = some(rating);
    }

    // Additional functions (optional)

    // Get the average rating of a driver
    public entry fun get_driver_avg_rating(driver_address: address, ctx: &mut TxContext): Option<u8> {
        let total_rating: u64 = 0;
        let num_ratings: u64 = 0;
        let objects = object::batch_borrow_mut<Ride>(&object::objects_for_sender(ctx, driver_address));

        loop {
            let (ride_obj, objs) = vector::pop_back(&mut objects);
            if (ride_obj == none()) {
                break
            };
            let ride = borrow_mut(&mut objs);
            if (is_some(&ride.driverRating)) {
                total_rating = total_rating + (*borrow(&ride.driverRating) as u64);
                num_ratings = num_ratings + 1;
            };
        };

        if (num_ratings == 0) {
            none()
        } else {
            some((total_rating / num_ratings) as u8)
        }
    }

    // Get the average rating of a rider
    public entry fun get_rider_avg_rating(rider_address: address, ctx: &mut TxContext): Option<u8> {
        let total_rating: u64 = 0;
        let num_ratings: u64 = 0;
        let objects = object::batch_borrow_mut<Ride>(&object::objects_for_sender(ctx, rider_address));

        loop {
            let (ride_obj, objs) = vector::pop_back(&mut objects);
            if (ride_obj == none()) {
                break
            };
            let ride = borrow_mut(&mut objs);
            if (is_some(&ride.riderRating)) {
                total_rating = total_rating + (*borrow(&ride.riderRating) as u64);
                num_ratings = num_ratings + 1;
            };
        };

        if (num_ratings == 0) {
            none()
        } else {
            some((total_rating / num_ratings) as u8)
        }
    }
}