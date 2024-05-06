## Ride Sharing Module Documentation

### Overview

The ride-sharing module facilitates the process of organizing rides between riders and drivers on a decentralized platform. It allows users to request rides, accept ride requests, complete rides, handle disputes, rate participants, and manage payments.

### Struct Definitions

#### Ride

- **id**: Unique identifier for each ride.
- **rider**: Address of the rider who requested the ride.
- **driver**: Address of the driver who accepted the ride request.
- **destination**: Destination of the ride.
- **price**: Price set for the ride.
- **escrow**: Escrow balance to hold funds until the ride is completed or disputed.
- **rideCompleted**: Flag indicating whether the ride has been completed.
- **dispute**: Flag indicating whether there is a dispute regarding the ride.
- **riderRating**: Optional rating given by the rider to the driver (0-5).
- **driverRating**: Optional rating given by the driver to the rider (0-5).

### Entry Functions

#### Request Ride

- **Function**: `request_ride`
- **Purpose**: Allows a user to request a ride by providing the destination and price.
- **Access**: Public
- **Arguments**: Destination (vector<u8>), Price (u64), Transaction Context (&mut TxContext)

#### Accept Ride

- **Function**: `accept_ride`
- **Purpose**: Allows a driver to accept a ride request.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Complete Ride

- **Function**: `complete_ride`
- **Purpose**: Marks a ride as completed.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Dispute Ride

- **Function**: `dispute_ride`
- **Purpose**: Initiates a dispute for a ride.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Resolve Dispute

- **Function**: `resolve_dispute`
- **Purpose**: Resolves a dispute by transferring funds to the appropriate party.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Resolved (bool), Transaction Context (&mut TxContext)

#### Release Payment

- **Function**: `release_payment`
- **Purpose**: Releases payment to the driver upon successful completion of the ride.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Cancel Ride

- **Function**: `cancel_ride`
- **Purpose**: Cancels a ride and refunds the rider if not yet paid.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Update Ride Destination

- **Function**: `update_ride_destination`
- **Purpose**: Allows the rider to update the destination of the ride.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), New Destination (vector<u8>), Transaction Context (&mut TxContext)

#### Update Ride Price

- **Function**: `update_ride_price`
- **Purpose**: Allows the rider to update the price of the ride.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), New Price (u64), Transaction Context (&mut TxContext)

#### Add Funds to Ride

- **Function**: `add_funds_to_ride`
- **Purpose**: Allows the rider to add funds to the ride's escrow balance.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Amount (Coin<SUI>), Transaction Context (&mut TxContext)

#### Request Refund

- **Function**: `request_refund`
- **Purpose**: Allows the rider to request a refund if the ride is not completed.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Mark Ride Complete

- **Function**: `mark_ride_complete`
- **Purpose**: Marks the ride as completed by the driver.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Transaction Context (&mut TxContext)

#### Rate Driver

- **Function**: `rateDriver`
- **Purpose**: Allows the driver to rate the rider.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Rating (u8), Transaction Context (&mut TxContext)

#### Rate Rider

- **Function**: `rateRider`
- **Purpose**: Allows the rider to rate the driver.
- **Access**: Public
- **Arguments**: Ride reference (&mut Ride), Rating (u8), Transaction Context (&mut TxContext)

### Additional Functions

#### Get Ride Destination

- **Function**: `get_ride_destination`
- **Purpose**: Retrieves the destination of a ride.
- **Access**: Public
- **Arguments**: Ride reference (&Ride)
- **Returns**: Destination (vector<u8>)

#### Get Ride Price

- **Function**: `get_ride_price`
- **Purpose**: Retrieves the price of a ride.
- **Access**: Public
- **Arguments**: Ride reference (&Ride)
- **Returns

**: Price (u64)

#### Withdraw Earnings

- **Function**: `withdraw_earnings`
- **Purpose**: Allows the driver to withdraw earnings from a completed ride.
- **Access**: Public
- **Arguments**: Ride reference (&Ride), Transaction Context (&mut TxContext)

#### View Ride Details

- **Function**: `view_ride_details`
- **Purpose**: Allows users to view details of a specific ride.
- **Access**: Public
- **Arguments**: Ride ID (UID), Transaction Context (&mut TxContext)
- **Returns**: Ride Details (Ride)

### Errors

- **EInvalidBid**: Invalid bid error code.
- **EInvalidRide**: Invalid ride error code.
- **EDispute**: Dispute error code.
- **EAlreadyResolved**: Dispute already resolved error code.
- **ENotDriver**: Not a driver error code.
- **EInvalidWithdrawal**: Invalid withdrawal error code.
- **EInvalidRating**: Invalid rating error code.
- **ENotRider**: Not a rider error code.

---

This documentation provides an overview of the ride-sharing module, including its struct definitions, entry functions, additional functions, and error codes. It serves as a guide for users and developers interacting with the module.