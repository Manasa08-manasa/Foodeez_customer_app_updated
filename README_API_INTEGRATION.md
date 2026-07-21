# Foodeez — Customer API Integration

All paths from `lib/core/constants/api_endpoints.dart` are wired through
`AppRepository` / `AppController`. Calls are **fail-soft**: seed/mock data
stays if the backend is unreachable. Screens and color theme are unchanged.

## Config

- `lib/core/constants/env.dart` → `https://int.foodeez.in/customer/api/v1`
- `lib/core/constants/api_endpoints.dart` → path constants below

## Endpoint map

| ApiEndpoints | When / where |
|--------------|--------------|
| **Auth** | |
| `sendOtp` / `login` / `signup` | Onboarding email OTP |
| `refresh` | App hydrate (quiet refresh) |
| `logout` | Account → Log out |
| `logoutAll` / `sessions` / `revokeSession` | Account → Settings / `logoutAllDevices()` |
| `resetPassword` | Available on `CustomerAuthApi` |
| **Discovery** | |
| `discoveryNearby` | App start / home refresh |
| `discoverySearch` | Search submit |
| `discoveryTrending` | App start → trending section |
| `discoveryPopularDishes` | App start → recent/popular chips |
| `restaurantDetails` | Open restaurant / profile |
| `restaurantMenu` | Open restaurant menu |
| **Cart** | |
| `cart` GET | Hydrate / after login / reorder |
| `cartItems` POST / PATCH / DELETE | Add / update / remove cart line |
| `cart` DELETE | `clearRemoteCart()` |
| `cartCoupon` | Apply / remove coupon |
| **Orders** | |
| `orders` POST | Place order at checkout |
| `orders` GET | Orders tab / after order |
| `order` GET | `getOrder` |
| `orderCancel` | Tracking menu → Cancel order |
| `orderReorder` | Orders → Reorder |
| `orderTracking` | Tracking screen open |
| **Profile** | |
| `profile` GET/PATCH | Account refresh / update |
| `profileImage` | `updateProfileImage` |
| `addresses` CRUD + set-default | Address book / hydrate |
| `favRestaurants` / `favItems` | Favourites sync + toggle |
| **Payments** | |
| `wallet` | Account / payment screen |
| `walletTransactions` | Payment screen open |
| `walletTopupInitiate` | `topupWallet()` |
| **Reviews** | |
| `reviews` POST | Orders → Rate |
| **Support** | |
| `supportTickets` | Help open + chat creates ticket |
| `supportTicket` | Ticket detail fetch |

Extra (not in ApiEndpoints, still fail-soft): `/coupons/catalog`, `/coupons/restaurant/{id}`,
`/customer/payments/initiate`, `/customer/payments/verify`.

Coupon catalog unwraps website shape `{ foodeezOffers, restaurantOffers }`.
Nearby discovery retries radii 50km → 100km → 500km (same as web discovery).

Dining / booking screens have **no** website APIs — keep mock/static data.
Promo ads, categories, help topics, payment method chips stay mock when not from API.

## Auth UI

Matches `new_frontend-dev/app/(customer)`:

- Login: email → OTP
- Signup: email → name + phone + OTP
- Guest: continue with mock data

## Live location + nearby

On launch (guest or logged-in):

1. `LocationService.ensureLocation()` → device GPS (fallback `17.4349, 78.3882`)
2. `GET /customer/discovery/nearby?lat=&lng=&radius=50000&limit=200` (public, no JWT)
3. Widen radius to 100km / 500km if empty
4. Home address label from Google Geocoding (Maps key) / Nominatim
5. Tracking screen uses Google Maps with the same key

Tap the home address row to refresh GPS + nearby.
