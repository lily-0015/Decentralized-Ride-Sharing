module ride_sharing::ride_sharing {

    // Imports
    use 0x1::P2P::P2P;
    use 0x1::Account::Account;
    use 0x1::LibraAccount::LibraAccount;
    use 0x1::Coin::Coin;
    use 0x1::Signer::Signer;
    use 0x1::LibraCoin::LibraCoin;
    use 0x1::Address::Address;

    // Errors
    const E_INVALID_BID: u64 = 1;
    const E_INVALID_RIDE: u64 = 2;
    const E_DISPUTE: u64 = 3;
    const E_ALREADY_RESOLVED: u64 = 4;
    const E_NOT_DRIVER: u64 = 5;
    const E_INVALID_WITHDRAWAL: u64 = 6;
    const E_INVALID_RATING: u64 = 7;
    const E_NOT_RIDER: u64 = 8;
    const MAX_ESCROW_MULTIPLIER: u64 = 2;

    // Struct definitions
    struct Ride {
        id: u64,
        rider: address,
        driver: Option<address>,
        destination: vector<u8>,
        price: u64,
        escrow: Coin<LibraCoin>,
        ride_completed: bool,
        dispute: bool,
        rider_rating: Option<u8>, // Rating given by the rider (0-5)
        driver_rating: Option<u8>, // Rating given by the driver (0-5)
        dispute_attempts: u64,
    }

    // Accessors
    public fun get_ride_destination(ride: &Ride): vector<u8> {
        ride.destination
    }

    public fun get_ride_price(ride: &Ride): u64 {
        ride.price
    }

    // Public - Entry functions
    public fun request_ride(destination: vector<u8>, price: u64, ctx: &mut Signer) {
        let ride_id = P2P::random();
        let ride = Ride {
            id: ride_id,
            rider: ctx.get_address(),
            driver: None,
            destination: destination,
            price: price,
            escrow: Coin::new(0),
            ride_completed: false,
            dispute: false,
            rider_rating: None,
            driver_rating: None,
            dispute_attempts: 0,
        };
        P2P::save(ride_id, ride);
    }

    public fun accept_ride(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(!ride.driver.exists(), E_INVALID_BID);
        ride.driver = Some(ctx.get_address());
    }

    public fun complete_ride(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.driver.contains(ctx.get_address()), E_INVALID_RIDE);
        ride.ride_completed = true;
    }

    public fun dispute_ride(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_DISPUTE);
        ride.dispute = true;
    }

    public fun resolve_dispute(ride_id: u64, resolved: bool, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_DISPUTE);
        assert!(ride.dispute, E_ALREADY_RESOLVED);
        assert!(ride.driver.exists(), E_INVALID_BID);

        let escrow_amount = ride.escrow.value();
        let escrow_coin = ride.escrow.take(escrow_amount);

        if resolved {
            // Transfer funds to the driver
            P2P::transfer_coins(escrow_coin, ride.driver.unwrap());
        } else {
            // Refund funds to the rider
            P2P::transfer_coins(escrow_coin, ride.rider);
        }

        // Reset ride state
        ride.driver = None;
        ride.ride_completed = false;
        ride.dispute = false;
        ride.dispute_attempts = 0;
    }

    public fun release_payment(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_NOT_DRIVER);
        assert!(ride.ride_completed && !ride.dispute, E_INVALID_RIDE);
        assert!(ride.driver.exists(), E_INVALID_BID);

        let escrow_amount = ride.escrow.value();
        let escrow_coin = ride.escrow.take(escrow_amount);

        // Transfer funds to the driver
        P2P::transfer_coins(escrow_coin, ride.driver.unwrap());

        // Reset ride state
        ride.driver = None;
        ride.ride_completed = false;
        ride.dispute = false;
    }

    // Additional functions
    public fun cancel_ride(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address() || ride.driver.contains(ctx.get_address()), E_NOT_DRIVER);

        // Refund funds to the rider if not yet paid
        if ride.driver.exists() && !ride.ride_completed && !ride.dispute {
            let escrow_amount = ride.escrow.value();
            let escrow_coin = ride.escrow.take(escrow_amount);
            P2P::transfer_coins(escrow_coin, ride.rider);
        }

        // Reset ride state
        ride.driver = None;
        ride.ride_completed = false;
        ride.dispute = false;
        ride.dispute_attempts = 0;
    }

    public fun update_ride_destination(ride_id: u64, new_destination: vector<u8>, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_NOT_DRIVER);
        ride.destination = new_destination;
    }

    public fun update_ride_price(ride_id: u64, new_price: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_NOT_DRIVER);
        assert!(new_price >= 0, E_INVALID_WITHDRAWAL);
        ride.price = new_price;
    }

    // New functions
    public fun add_funds_to_ride(ride_id: u64, amount: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_NOT_DRIVER);
        assert!(ride.escrow.value() + amount <= ride.price * MAX_ESCROW_MULTIPLIER, E_INVALID_WITHDRAWAL);
        ride.escrow = ride.escrow.join(amount);
    }

    public fun request_refund(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_NOT_DRIVER);
        assert!(!ride.ride_completed, E_INVALID_WITHDRAWAL);

        let escrow_amount = ride.escrow.value();
        let escrow_coin = ride.escrow.take(escrow_amount);
        // Refund funds to the rider
        P2P::transfer_coins(escrow_coin, ride.rider);

        // Reset ride state
        ride.driver = None;
        ride.ride_completed = false;
        ride.dispute = false;
        ride.dispute_attempts = 0;
    }

    public fun mark_ride_complete(ride_id: u64, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.driver.contains(ctx.get_address()), E_NOT_DRIVER);
        ride.ride_completed = true;
    }

    public fun rate_driver(ride_id: u64, rating: u8, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.driver.contains(ctx.get_address()), E_NOT_DRIVER);
        assert!(ride.ride_completed && !ride.dispute, E_INVALID_RIDE);
        assert!(rating <= 5, E_INVALID_RATING);
        ride.driver_rating = Some(rating);
    }

    public fun rate_rider(ride_id: u64, rating: u8, ctx: &mut Signer) {
        let mut ride = P2P::borrow_mut(ride_id);
        assert!(ride.rider == ctx.get_address(), E_NOT_RIDER);
        assert!(ride.ride_completed && !ride.dispute, E_INVALID_RIDE);
        assert!(rating <= 5, E_INVALID_RATING);
        ride.rider_rating = Some(rating);
    }
}
