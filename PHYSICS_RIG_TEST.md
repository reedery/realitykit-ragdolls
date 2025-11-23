# Physics-Based Articulation Test

## What We Built

A **physics-based ragdoll system** that creates actual movable joints using RealityKit's physics engine!

## How It Works

Instead of trying to modify the read-only skeleton, we:

1. Create **physical rigid bodies** (orange box = arm bone)
2. Add **physics joints** connecting them (ball-and-socket at shoulder)
3. Make the end **draggable** (green sphere = hand)
4. Physics engine handles **natural rotation** automatically!

## What You'll See

### Visual Elements:

- 🔴 **Red Sphere** - Fixed shoulder anchor (doesn't move)
- 🟠 **Orange Box** - Arm bone segment (rigid body, can rotate)
- 🟢 **Green Sphere** - Draggable hand marker (grab this!)

### Setup:

```
    Shoulder (red, fixed)
         |
         | <- Ball-socket joint (allows rotation)
         |
    Arm Bone (orange box)
         |
    Hand Marker (green, draggable)
```

## Testing

1. **Run the app**
2. **Look for**:

   - Red sphere at shoulder height (1.5m up)
   - Orange box below it (the arm)
   - Green sphere at the end (the hand)

3. **Try dragging** the green sphere
4. **The orange arm should rotate** around the red anchor point!

## Expected Console Output

```
=== Setting Up Physics-Based Articulation ===
Creating arm segment between:
  Start: joint_45 at (...)
  End: joint_89 at (...)
✓ Created physics test rig with 1 arm segment
  Bone entity: bone_joint_45_to_joint_89
  Try dragging the hand marker!
```

## If It Works 🎉

You'll see the arm **naturally swing and rotate** as you drag the hand!

- Physics automatically handles momentum
- Joint constraints keep it connected
- Realistic movement!

## Next Steps

Once this works, we can:

1. Add more bone segments (forearm, upper arm separately)
2. Connect them with multiple joints
3. Add joint limits (like real elbow/shoulder range)
4. Create a full-body rig!

## Troubleshooting

**Don't see the spheres/box?**

- Check console for error messages
- Make sure robot loaded successfully

**Can drag but nothing rotates?**

- Physics joint might not be configured correctly
- May need to adjust PhysicsJointComponent parameters

**Orange box falls or flies away?**

- Physics is working! Just needs tuning
- Might need to add damping or adjust mass
