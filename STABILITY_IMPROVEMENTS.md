# RagDoll Physics Stability Improvements

## Root Cause Analysis

Based on your physics first-principles analysis, here are the critical issues and their fixes:

### 1. 🔴 CRITICAL: Penetration/Collision Issues

**Problem:**
- Colliders at 87-90% of visual size still cause overlap
- No Continuous Collision Detection (CCD) = tunneling through geometry
- Bodies can phase through each other and explode when physics corrects

**Solution:**
✅ Reduce collider size to **70% of visual** (vs current 87-90%)
✅ **Enable CCD on all dynamic bodies** (`isCCDEnabled = true`)
✅ Increase spawn spacing to **1.6-1.8x** (vs current 1.3-1.5x)

### 2. 🔴 CRITICAL: Mass Ratio Problems

**Current Ratios** (UNSTABLE):
```
Torso:      8.0-10.0
Lower Arm:  0.7-1.0
Ratio:      10:1 to 14:1  ❌ TOO EXTREME
```

**Problem**: Light limbs get "thrown" by heavy torso, solver can't handle extreme ratios

**Solution** (STABLE):
```
Torso:      6.0-6.5     (reduced)
Lower Arm:  2.0-2.3     (increased)
Ratio:      2.6:1 to 3.0:1  ✅ STABLE
```

**All Mass Updates:**
- Default: torso 6.0, limbs 2.0-3.0 (was 8.0, 0.8-1.5)
- Tall: torso 5.5, limbs 2.0-2.8 (was 7.0, 0.7-1.3)
- Short: torso 6.5, limbs 2.2-3.2 (was 9.0, 0.9-1.7)
- Muscular: torso 6.0, limbs 2.3-3.5 (was 10.0, 1.0-2.0)

### 3. 🟡 HIGH: Solver Iterations

**Current**: 80 position, 80 velocity
**Problem**: Not enough for 10 bodies + 9 joints
**Solution**: Increase to **150 position, 150 velocity**

### 4. 🟡 HIGH: No Sleep Thresholds

**Problem**: Bodies never rest, micro-jitter accumulates into chaos
**Solution**: Add sleep threshold = **0.01** for both linear and angular

### 5. 🟡 MEDIUM: Friction Too High

**Current**: Static 0.9, Dynamic 0.8
**Problem**: Causes "stick-slip" behavior - bodies stick then suddenly release with force
**Solution**: Reduce to Static **0.5**, Dynamic **0.4**

### 6. 🟡 MEDIUM: No Angular Velocity Limits

**Problem**: Limbs can spin infinitely fast, creating huge destabilizing momentum
**Solution**: Cap at **20 rad/s** (~3 rotations per second)

### 7. 🟢 LOW: Damping Values

**Current**: Angular 10-15, Linear 7-10
**Solution**: Increase significantly for all characters:
- Default: Angular 18, Linear 12 (extremities: 22, 15)
- Tall: Angular 20, Linear 13 (extremities: 24, 16)
- Short: Angular 16, Linear 11 (extremities: 20, 14)
- Muscular: Angular 17, Linear 11.5 (extremities: 21, 14.5)

### 8. 🟢 LOW: Gravity & Restitution

**Gravity**: Reduce from -6.0 to **-4.0** (gentler, more controllable)
**Restitution**: Reduce from 0.01 to **0.0** (absolutely no bounce)

## Implementation Priority

1. **IMMEDIATE** (Apply First):
   - Enable CCD on all dynamic bodies
   - Update mass ratios (reduce torso, increase limbs)
   - Reduce collider sizes to 70%

2. **HIGH** (Apply Second):
   - Increase solver iterations to 150
   - Add sleep thresholds (0.01)
   - Reduce friction (0.5/0.4)

3. **MEDIUM** (Fine-tuning):
   - Add max angular velocity (20 rad/s)
   - Increase damping values
   - Reduce gravity and restitution

## Code Changes Required

### File: `StableRagdollPhysics.swift` (NEW)
Created comprehensive stability module with:
- CCD enabled by default
- Mass normalization (enforces 3:1 max ratio)
- Sleep thresholds
- Max angular velocity limits
- Helper methods for collider sizing

### File: `CharacterConfiguration.swift` (UPDATE)
Need to update all 4 character presets with new mass values and physics properties.

### File: `RagdollBuilder.swift` (UPDATE)
Need to:
- Use `StableRagdollPhysics` instead of `RagdollPhysics`
- Apply 70% collider sizing
- Increase joint spacing to 1.6-1.8x

### File: `PhysicsConfiguration.swift` (UPDATE)
Update defaults:
- positionIterations: 150 (was 80)
- velocityIterations: 150 (was 80)
- gravity: -4.0 (was -6.0)
- staticFriction: 0.5 (was 0.9)
- dynamicFriction: 0.4 (was 0.8)
- restitution: 0.0 (was 0.01)

## Expected Results

✅ **Dramatically reduced "explosions"** - CCD prevents tunneling
✅ **Smoother motion** - Better mass ratios and friction
✅ **Bodies can rest** - Sleep thresholds stop micro-jitter
✅ **No crazy spinning** - Angular velocity limits
✅ **Faster stabilization** - Higher solver iterations
✅ **More predictable** - Lower gravity, no bounce

## Testing Plan

1. **Test Default character first** - Should be most stable
2. **Drag torso gently** - Check for smooth movement
3. **Let go** - Should settle in 2-3 seconds (vs minutes currently)
4. **Drag more violently** - Should recover without exploding
5. **Test other characters** - All should have similar stability

## Rollback Plan

If stability gets worse:
1. Revert mass changes first
2. Then revert collider size
3. Keep CCD, sleep, and velocity limits (they're always beneficial)
