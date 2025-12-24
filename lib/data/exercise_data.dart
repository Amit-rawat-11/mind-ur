import 'package:cloud_firestore/cloud_firestore.dart';
final List<Map<String, dynamic>> workoutData = [
  // --- Popular Bodyweight Exercises (No Equipment) ---

  {
    "name": "Push-ups (Dands)",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "None",
    "instructions": "Start in a plank position, lower your chest towards the ground, arching your back slightly, then push forward like a wave, bringing your chest up while keeping your hips low. Reverse the motion to return.",
    "isBodyweight": true,
    "searchKeywords": ["pushup", "dands", "chest", "shoulders", "triceps", "bodyweight", "indian"]
  },
  {
    "name": "Squats (Baithaks)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Stand with feet shoulder-width apart. Lower your body into a squat while swinging your arms forward. As you rise, roll onto the balls of your feet, lifting your heels.",
    "isBodyweight": true,
    "searchKeywords": ["squat", "baithaks", "legs", "glutes", "bodyweight", "indian"]
  },
  {
    "name": "Plank",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Hold a straight line from head to heels, supporting yourself on your forearms or hands and toes. Keep your core tight.",
    "isBodyweight": true,
    "searchKeywords": ["plank", "core", "abs", "bodyweight"]
  },
  {
    "name": "Lunges (Bodyweight)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Step forward with one leg, lowering your hips until both knees are bent at a 90-degree angle. Push back to the start and alternate legs.",
    "isBodyweight": true,
    "searchKeywords": ["lunge", "legs", "glutes", "bodyweight"]
  },
  {
    "name": "Running Jogging", // Name modified
    "category": "Cardio",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Engage in continuous running or jogging at a comfortable pace, maintaining good posture and breathing.",
    "isBodyweight": true,
    "searchKeywords": ["running", "jogging", "cardio", "legs", "outdoor"]
  },
  {
    "name": "Jumping Jacks",
    "category": "Cardio",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Start with feet together and arms at your sides. Jump, spreading your feet wide and bringing your arms overhead. Jump back to the starting position.",
    "isBodyweight": true,
    "searchKeywords": ["jumping jack", "cardio", "full body", "bodyweight"]
  },
  {
    "name": "Mountain Climbers",
    "category": "Cardio",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Start in a high plank position. Alternately bring one knee towards your chest, then switch legs, mimicking a running motion.",
    "isBodyweight": true,
    "searchKeywords": ["mountain climber", "cardio", "core", "bodyweight"]
  },
  {
    "name": "Burpees",
    "category": "Cardio, Strength",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Perform a squat, then kick your feet back into a plank, optionally do a push-up, jump your feet back to the squat position, and then jump explosively upwards.",
    "isBodyweight": true,
    "searchKeywords": ["burpee", "cardio", "full body", "bodyweight"]
  },
  {
    "name": "Crunches",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Lie on your back with knees bent and feet flat. Place hands behind your head, then lift your head and shoulders off the ground, engaging your abs.",
    "isBodyweight": true,
    "searchKeywords": ["crunch", "abs", "core", "bodyweight"]
  },
  {
    "name": "Glute Bridge",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Lie on your back with knees bent, feet flat. Lift your hips off the ground until your body forms a straight line from shoulders to knees.",
    "isBodyweight": true,
    "searchKeywords": ["glute bridge", "glutes", "hamstrings", "bodyweight"]
  },
  {
    "name": "High Knees",
    "category": "Cardio",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Run in place, bringing your knees up towards your chest as high as possible.",
    "isBodyweight": true,
    "searchKeywords": ["high knees", "cardio", "legs", "bodyweight"]
  },
  {
    "name": "Tricep Dips (Bench Chair)", // Name modified
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Bench, Chair",
    "instructions": "Place hands on the edge of a sturdy bench or chair behind you. Lower your body by bending your elbows, then push back up.",
    "isBodyweight": true,
    "searchKeywords": ["tricep dip", "triceps", "bodyweight"]
  },
  {
    "name": "Calf Raises (Bodyweight)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Stand tall, raise up onto the balls of your feet, then lower slowly.",
    "isBodyweight": true,
    "searchKeywords": ["calf raise", "calves", "bodyweight"]
  },
  {
    "name": "Leg Raises (Lying)",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Lie on your back, keep your legs straight and lift them towards the ceiling, then lower slowly and controlled.",
    "isBodyweight": true,
    "searchKeywords": ["leg raise", "abs", "core", "bodyweight"]
  },
  {
    "name": "Superman",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "None",
    "instructions": "Lie on your stomach, extend arms forward. Lift your arms, chest, and legs off the ground simultaneously, squeezing your lower back and glutes.",
    "isBodyweight": true,
    "searchKeywords": ["superman", "back", "glutes", "bodyweight"]
  },

  // --- Popular Yoga Asanas (Non-Equipment) ---

  {
    "name": "Surya Namaskar (Sun Salutations)",
    "category": "Yoga (Flow)",
    "muscleGroup": "Core", // Primarily core for flow, but full body
    "equipment": "Mat (optional)",
    "instructions": "A series of 12 flowing poses, typically done at sunrise, integrating breath with movement. Includes poses like Mountain, Raised Arms, Forward Fold, Plank, Cobra, Downward Dog, etc.",
    "isBodyweight": true,
    "searchKeywords": ["suryanamaskar", "yoga", "full body", "flow", "flexibility"]
  },
  {
    "name": "Downward-Facing Dog (Adho Mukha Svanasana)",
    "category": "Yoga (Strength Flexibility)", // Name modified
    "muscleGroup": "Legs",
    "equipment": "Mat (optional)",
    "instructions": "Form an inverted 'V' shape with your body, pressing your palms and heels down, lifting hips towards the sky.",
    "isBodyweight": true,
    "searchKeywords": ["downward dog", "yoga", "stretch", "strength", "bodyweight"]
  },
  {
    "name": "Cobra Pose (Bhujangasana)",
    "category": "Yoga (Strength Flexibility)", // Name modified
    "muscleGroup": "Back",
    "equipment": "Mat (optional)",
    "instructions": "Lie face down, hands under shoulders. Press into palms, lift chest off the ground, arching your back, keeping elbows slightly bent.",
    "isBodyweight": true,
    "searchKeywords": ["cobra pose", "yoga", "backbend", "flexibility", "bodyweight"]
  },
  {
    "name": "Tree Pose (Vrikshasana)",
    "category": "Yoga (Balance Strength)", // Name modified
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Stand tall, shift weight to one foot. Place the sole of your other foot on your inner thigh or calf (avoiding the knee). Bring hands to prayer at heart or overhead.",
    "isBodyweight": true,
    "searchKeywords": ["tree pose", "yoga", "balance", "legs", "bodyweight"]
  },
  {
    "name": "Warrior II (Virabhadrasana II)",
    "category": "Yoga (Strength Balance)", // Name modified
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Stand with wide stance, front knee bent to 90 degrees, back leg straight. Extend arms parallel to floor, gazing over front hand.",
    "isBodyweight": true,
    "searchKeywords": ["warrior pose", "yoga", "strength", "legs", "bodyweight"]
  },
  {
    "name": "Bridge Pose (Setu Bandhasana)",
    "category": "Yoga (Strength Flexibility)", // Name modified
    "muscleGroup": "Legs",
    "equipment": "Mat (optional)",
    "instructions": "Lie on your back, knees bent, feet flat near glutes. Lift hips towards the ceiling, clasping hands underneath or resting arms by your sides.",
    "isBodyweight": true,
    "searchKeywords": ["bridge pose", "yoga", "glutes", "back", "bodyweight"]
  },
  {
    "name": "Cat-Cow Stretch (Marjaryasana Bitilasana)", // Name modified
    "category": "Yoga (Flexibility Mobility)", // Name modified
    "muscleGroup": "Core",
    "equipment": "Mat (optional)",
    "instructions": "On hands and knees, inhale as you arch your back and lift your head (Cow). Exhale as you round your back and tuck your chin (Cat). Flow between the two.",
    "isBodyweight": true,
    "searchKeywords": ["cat cow", "yoga", "spine", "flexibility", "bodyweight"]
  },

  // --- Popular Gym Exercises (with Equipment) ---

  {
    "name": "Barbell Bench Press (Flat)",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "Barbell, Bench, Rack",
    "instructions": "Lie on a flat bench, unrack the barbell over your chest. Lower the bar to your mid-chest, then press it back up to the starting position.",
    "isBodyweight": false,
    "searchKeywords": ["bench press", "barbell", "chest", "gym"]
  },
  {
    "name": "Barbell Deadlift (Conventional)",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Barbell, Weight Plates",
    "instructions": "Stand with feet hip-width apart, bar over mid-foot. Hinge at hips, grasp bar with mixed or overhand grip. Lift the bar by extending hips and knees, keeping back straight.",
    "isBodyweight": false,
    "searchKeywords": ["deadlift", "barbell", "full body", "gym"]
  },
  {
    "name": "Barbell Back Squat",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Barbell, Rack, Weight Plates",
    "instructions": "Position the barbell on your upper back. Squat down by sending your hips back and bending your knees, keeping your chest up and back straight. Drive back up.",
    "isBodyweight": false,
    "searchKeywords": ["back squat", "barbell", "legs", "glutes", "gym"]
  },
  {
    "name": "Dumbbell Rows (Bent-Over Single-Arm)", // Name modified
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Dumbbells, Bench (optional)",
    "instructions": "Support one hand/knee on a bench (for single-arm). With a dumbbell in the other hand, pull the dumbbell towards your hip, squeezing your shoulder blade.",
    "isBodyweight": false,
    "searchKeywords": ["dumbbell row", "back", "biceps", "gym"]
  },
  {
    "name": "Barbell Dumbbell Overhead Press (Shoulder Press)", // Name modified
    "category": "Strength",
    "muscleGroup": "Shoulder",
    "equipment": "Barbell or Dumbbells, Bench (optional)",
    "instructions": "Press the barbell or dumbbells directly overhead from a front rack position (barbell) or shoulder height (dummies), then lower with control.",
    "isBodyweight": false,
    "searchKeywords": ["overhead press", "shoulder press", "barbell", "dumbbell", "shoulders", "gym"]
  },
  {
    "name": "Dumbbell Bicep Curl",
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Dumbbells",
    "instructions": "Stand or sit, hold dumbbells at your sides with palms facing forward. Curl the dumbbells up towards your shoulders, squeezing your biceps, then lower slowly.",
    "isBodyweight": false,
    "searchKeywords": ["bicep curl", "dumbbell", "arms", "gym"]
  },
  {
    "name": "Lat Pulldown (Machine)",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Lat Pulldown Machine",
    "instructions": "Sit at the machine, grasp the bar with a wide grip. Pull the bar down towards your upper chest, squeezing your shoulder blades together, then slowly release.",
    "isBodyweight": false,
    "searchKeywords": ["lat pulldown", "back", "machine", "gym"]
  },
  {
    "name": "Seated Cable Row",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Cable Row Machine",
    "instructions": "Sit with feet on the footplate, knees slightly bent. Grasp the handle and pull it towards your lower abdomen, squeezing your shoulder blades.",
    "isBodyweight": false,
    "searchKeywords": ["cable row", "back", "machine", "gym"]
  },
  {
    "name": "Leg Press (Machine)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Leg Press Machine",
    "instructions": "Sit on the machine, place feet on the platform. Push the platform away by extending your legs, then slowly lower the weight.",
    "isBodyweight": false,
    "searchKeywords": ["leg press", "quads", "glutes", "hamstrings", "machine", "gym"]
  },
  {
    "name": "Leg Extension (Machine)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Leg Extension Machine",
    "instructions": "Sit on the machine, with the pad resting on your shins. Extend your lower legs upwards, straightening your knees, then slowly lower the weight.",
    "isBodyWeight": false,
    "searchKeywords": ["leg extension", "quads", "machine", "gym"]
  },
  {
    "name": "Hamstring Curl (Machine - Lying Seated)", // Name modified
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Hamstring Curl Machine",
    "instructions": "Lie face down or sit on the machine. Curl your legs up against the pad towards your glutes, then slowly release.",
    "isBodyweight": false,
    "searchKeywords": ["hamstring curl", "hamstrings", "machine", "gym"]
  },
  {
    "name": "Cable Tricep Pushdown",
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Cable Machine",
    "instructions": "Attach a rope or bar to a high pulley. Grasp the handle and push it downwards, extending your elbows, keeping your upper arms stationary.",
    "isBodyweight": false,
    "searchKeywords": ["tricep pushdown", "cable", "triceps", "gym"]
  },
  {
    "name": "Treadmill Running Walking", // Name modified
    "category": "Cardio",
    "muscleGroup": "Legs",
    "equipment": "Treadmill",
    "instructions": "Set desired speed and incline on a treadmill for cardio exercise.",
    "isBodyweight": false,
    "searchKeywords": ["treadmill", "running", "walking", "cardio", "gym"]
  },
  {
    "name": "Elliptical Trainer",
    "category": "Cardio",
    "muscleGroup": "Legs",
    "equipment": "Elliptical Trainer",
    "instructions": "Use the elliptical for a low-impact full-body cardiovascular workout.",
    "isBodyweight": false,
    "searchKeywords": ["elliptical", "cardio", "full body", "gym"]
  },
  {
    "name": "Stationary Bike",
    "category": "Cardio",
    "muscleGroup": "Legs",
    "equipment": "Stationary Bike",
    "instructions": "Pedal on a stationary upright or recumbent bike at your chosen resistance and speed.",
    "isBodyweight": false,
    "searchKeywords": ["stationary bike", "cycling", "cardio", "legs", "gym"]
  },
  {
    "name": "Kettlebell Swing",
    "category": "Strength, Cardio",
    "muscleGroup": "Legs",
    "equipment": "Kettlebell",
    "instructions": "Hinge at your hips, swing the kettlebell back between your legs, then explosively extend your hips to propel the kettlebell to chest height.",
    "isBodyweight": false,
    "searchKeywords": ["kettlebell swing", "glutes", "hamstrings", "cardio", "gym"]
  },
  {
    "name": "Kettlebell Goblet Squat",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Kettlebell",
    "instructions": "Hold a kettlebell by the horns at your chest. Perform a squat, keeping your chest up and elbows inside your knees.",
    "isBodyweight": false,
    "searchKeywords": ["goblet squat", "kettlebell", "legs", "glutes", "gym"]
  },
  {
    "name": "Barbell Row (Bent-Over)",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Barbell, Weight Plates",
    "instructions": "Bend at your waist, keeping your back flat and chest out. Pull the barbell towards your lower chest/upper abdomen, squeezing your shoulder blades.",
    "isBodyweight": false,
    "searchKeywords": ["barbell row", "back", "biceps", "gym"]
  },

  // --- Additional Bodyweight & Gym Exercises (Expanding the list) ---

  {
    "name": "Skipping Jump Rope", // Name modified
    "category": "Cardio, Plyometrics",
    "muscleGroup": "Legs",
    "equipment": "Jump Rope",
    "instructions": "Jump over a skipping rope, using your wrists to rotate it, maintaining a steady rhythm.",
    "isBodyweight": true,
    "searchKeywords": ["skipping", "jump rope", "cardio", "plyometrics", "bodyweight"]
  },
  {
    "name": "Assisted Pull-ups Pull-ups", // Name modified
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Pull-up Bar (or Assisted Pull-up Machine)",
    "instructions": "Hang from a pull-up bar with an overhand grip. Pull your body up until your chin clears the bar, then lower with control.",
    "isBodyweight": true, // Can be bodyweight or assisted
    "searchKeywords": ["pullup", "chinup", "back", "biceps", "bodyweight", "gym"]
  },
  {
    "name": "Assisted Dips Dips", // Name modified
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "Dip Bars (or Assisted Dip Machine)",
    "instructions": "Grasp parallel bars, lower your body by bending your elbows, then push back up until arms are straight.",
    "isBodyweight": true, // Can be bodyweight or assisted
    "searchKeywords": ["dip", "chest", "triceps", "shoulders", "bodyweight", "gym"]
  },
  {
    "name": "Plank Shoulder Taps",
    "category": "Core, Stability",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Hold a high plank position. Alternately tap your opposite shoulder with one hand, striving to keep your hips still and level.",
    "isBodyweight": true,
    "searchKeywords": ["plank", "shoulder taps", "core", "stability", "bodyweight"]
  },
  {
    "name": "Russian Twists (Bodyweight)",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Sit on the floor, lean back slightly, lift your feet off the ground (or keep them down for easier). Twist your torso from side to side.",
    "isBodyweight": true,
    "searchKeywords": ["russian twist", "obliques", "core", "bodyweight"]
  },
  {
    "name": "Side Plank",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Support your body on one forearm and the side of your foot, keeping your body in a straight line from head to heels.",
    "isBodyweight": true,
    "searchKeywords": ["side plank", "obliques", "core", "bodyweight"]
  },
  {
    "name": "Bicycle Crunches",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Lie on your back, hands behind head, knees bent. Bring opposite elbow to opposite knee while extending the other leg.",
    "isBodyweight": true,
    "searchKeywords": ["bicycle crunch", "abs", "obliques", "bodyweight"]
  },
  {
    "name": "Bird Dog",
    "category": "Core, Stability",
    "muscleGroup": "Core",
    "equipment": "None",
    "instructions": "Start on hands and knees. Extend one arm forward and the opposite leg backward simultaneously, maintaining a stable core and flat back.",
    "isBodyweight": true,
    "searchKeywords": ["bird dog", "core", "stability", "bodyweight"]
  },
  {
    "name": "Glute Kickback (Bodyweight)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "On hands and knees, keep one knee on the ground and kick the other leg straight back and up, squeezing the glute.",
    "isBodyweight": true,
    "searchKeywords": ["glute kickback", "glutes", "bodyweight"]
  },
  {
    "name": "Good Mornings (Bodyweight Light Weight)", // Name modified
    "category": "Strength",
    "muscleGroup": "Legs", // Targets hamstrings and glutes primarily
    "equipment": "None / Light Barbell / PVC pipe",
    "instructions": "Stand tall, hands behind head (bodyweight) or light bar on back. Hinge at hips, keeping legs slightly bent and back straight, lowering torso towards parallel.",
    "isBodyweight": true,
    "searchKeywords": ["good morning", "hamstrings", "glutes", "lower back", "bodyweight"]
  },
  {
    "name": "Wall Sit",
    "category": "Strength (Isometric)",
    "muscleGroup": "Legs",
    "equipment": "Wall",
    "instructions": "Lean your back against a wall, slide down until your knees are bent at a 90-degree angle, holding the position.",
    "isBodyweight": true,
    "searchKeywords": ["wall sit", "quads", "isometric", "bodyweight"]
  },
  {
    "name": "Hindu Push-ups (Dand Variations)",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "None",
    "instructions": "Similar to Dands, involves a flowing motion from an inverted V to a cobra-like extension and back.",
    "isBodyweight": true,
    "searchKeywords": ["hindu pushup", "dand", "full body", "bodyweight"]
  },
  {
    "name": "Box Jumps (Low Box Step)", // Name modified
    "category": "Plyometrics",
    "muscleGroup": "Legs",
    "equipment": "Low Box/Step",
    "instructions": "Stand in front of a sturdy box/step. Jump onto the box with both feet, landing softly, then step or jump back down.",
    "isBodyweight": true, // Can be done without a high box.
    "searchKeywords": ["box jump", "plyometrics", "legs", "bodyweight"]
  },
  {
    "name": "Jump Squats",
    "category": "Plyometrics, Cardio",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Perform a regular squat, then explode upwards into a jump, landing softly back into a squat.",
    "isBodyweight": true,
    "searchKeywords": ["jump squat", "plyometrics", "cardio", "legs", "bodyweight"]
  },
  {
    "name": "Lunge Jumps (Alternating)",
    "category": "Plyometrics, Cardio",
    "muscleGroup": "Legs",
    "equipment": "None",
    "instructions": "Start in a lunge. Jump explosively upwards, switching legs in the air, landing in a lunge with the opposite leg forward.",
    "isBodyweight": true,
    "searchKeywords": ["lunge jump", "plyometrics", "cardio", "legs", "bodyweight"]
  },
  {
    "name": "Dumbbell Fly (Flat Bench)",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "Dumbbells, Bench",
    "instructions": "Lie on a flat bench, hold dumbbells above your chest with a slight bend in your elbows. Open your arms out to the sides, then bring them back together over your chest.",
    "isBodyweight": false,
    "searchKeywords": ["dumbbell fly", "chest", "gym"]
  },
  {
    "name": "Dumbbell Tricep Extension (Overhead)",
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Dumbbell",
    "instructions": "Hold one dumbbell with both hands overhead. Lower the dumbbell behind your head by bending your elbows, then extend your arms to push it back up.",
    "isBodyweight": false,
    "searchKeywords": ["tricep extension", "dumbbell", "triceps", "gym"]
  },
  {
    "name": "Dumbbell Lateral Raise",
    "category": "Strength",
    "muscleGroup": "Shoulder",
    "equipment": "Dumbbells",
    "instructions": "Stand with dumbbells at your sides. Raise your arms out to the sides until they are parallel to the floor, keeping a slight bend in your elbows. Lower slowly.",
    "isBodyweight": false,
    "searchKeywords": ["lateral raise", "dumbbell", "shoulders", "gym"]
  },
  {
    "name": "Dumbbell Front Raise",
    "category": "Strength",
    "muscleGroup": "Shoulder",
    "equipment": "Dumbbells",
    "instructions": "Stand with dumbbells in front of your thighs. Raise your arms forward until they are parallel to the floor, then lower slowly.",
    "isBodyweight": false,
    "searchKeywords": ["front raise", "dumbbell", "shoulders", "gym"]
  },
  {
    "name": "Dumbbell Romanian Deadlift (RDL)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Dumbbells",
    "instructions": "Hold dumbbells in front of your thighs. Hinge at your hips, keeping your legs mostly straight and back flat, lowering the dumbbells towards your shins. Squeeze glutes to return.",
    "isBodyweight": false,
    "searchKeywords": ["RDL", "dumbbell deadlift", "hamstrings", "glutes", "gym"]
  },
  {
    "name": "Cable Crossover (Chest Fly)",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "Cable Crossover Machine",
    "instructions": "Stand between the cable pulleys, grasp a handle in each hand. Bring your hands together in front of your chest, simulating a hugging motion.",
    "isBodyweight": false,
    "searchKeywords": ["cable crossover", "chest fly", "chest", "gym"]
  },
  {
    "name": "Machine Shoulder Press",
    "category": "Strength",
    "muscleGroup": "Shoulder",
    "equipment": "Shoulder Press Machine",
    "instructions": "Sit on the machine, grasp the handles. Press the handles upwards until your arms are extended, then slowly lower.",
    "isBodyweight": false,
    "searchKeywords": ["shoulder press", "machine", "shoulders", "gym"]
  },
  {
    "name": "Machine Chest Press",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "Chest Press Machine",
    "instructions": "Sit on the machine, grasp the handles. Push the handles forward, extending your arms, then slowly return to the start.",
    "isBodyweight": false,
    "searchKeywords": ["chest press", "machine", "chest", "gym"]
  },
  {
    "name": "Rowing Machine",
    "category": "Cardio",
    "muscleGroup": "Back", // Primary muscles for the pulling motion
    "equipment": "Rowing Machine",
    "instructions": "Perform a smooth rowing motion using your legs, core, and arms, simulating pulling oars through water.",
    "isBodyweight": false,
    "searchKeywords": ["rowing machine", "cardio", "full body", "gym"]
  },
  {
    "name": "Barbell Bicep Curl",
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Barbell",
    "instructions": "Stand with a barbell, hands underhand grip, shoulder-width apart. Curl the barbell up towards your shoulders, then lower slowly.",
    "isBodyweight": false,
    "searchKeywords": ["barbell curl", "biceps", "arms", "gym"]
  },
  {
    "name": "Barbell Tricep Extension (Skullcrusher)",
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Barbell (EZ Curl Bar often preferred), Bench",
    "instructions": "Lie on a flat bench, hold a barbell above your chest. Lower the bar towards your forehead by bending your elbows, then extend your arms.",
    "isBodyweight": false,
    "searchKeywords": ["skullcrusher", "tricep extension", "barbell", "triceps", "gym"]
  },
  {
    "name": "Barbell Shrug",
    "category": "Strength",
    "muscleGroup": "Shoulder",
    "equipment": "Barbell, Weight Plates",
    "instructions": "Hold a heavy barbell in front of your thighs. Shrug your shoulders up towards your ears, then lower with control.",
    "isBodyweight": false,
    "searchKeywords": ["barbell shrug", "traps", "shoulders", "gym"]
  },
  {
    "name": "Dumbbell Shrug",
    "category": "Strength",
    "muscleGroup": "Shoulder",
    "equipment": "Dumbbells",
    "instructions": "Hold heavy dumbbells at your sides. Shrug your shoulders up towards your ears, then lower with control.",
    "isBodyweight": false,
    "searchKeywords": ["dumbbell shrug", "traps", "shoulders", "gym"]
  },
  {
    "name": "Hyperextension (Back Extension)",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Hyperextension Bench",
    "instructions": "Anchor your feet on the bench. Hinge at your hips, lowering your torso towards the floor, then extend back up, engaging your lower back and glutes.",
    "isBodyweight": false,
    "searchKeywords": ["back extension", "hyperextension", "lower back", "glutes", "gym"]
  },
  {
    "name": "Medicine Ball Slams",
    "category": "Power, Cardio",
    "muscleGroup": "Core",
    "equipment": "Medicine Ball",
    "instructions": "Lift a medicine ball overhead, then explosively slam it down to the ground, engaging your core and full body.",
    "isBodyweight": false,
    "searchKeywords": ["medicine ball slam", "power", "cardio", "full body", "gym"]
  },
  {
    "name": "Push Press (Barbell Dumbbell)", // Name modified
    "category": "Strength, Power",
    "muscleGroup": "Shoulder",
    "equipment": "Barbell or Dumbbells",
    "instructions": "Use a slight dip and drive from your legs to help press the weight overhead, finishing with arms extended.",
    "isBodyweight": false,
    "searchKeywords": ["push press", "barbell", "dumbbell", "shoulders", "power", "gym"]
  },
  {
    "name": "Goblet Squat (Dumbbell)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Dumbbell",
    "instructions": "Hold one end of a dumbbell vertically against your chest. Perform a squat, keeping your chest up and elbows inside your knees.",
    "isBodyweight": false,
    "searchKeywords": ["goblet squat", "dumbbell", "legs", "glutes", "gym"]
  },
  {
    "name": "Bulgarian Split Squat (Dumbbell)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Dumbbells, Bench/Step",
    "instructions": "Place the top of one foot on a bench behind you. Hold dumbbells at your sides. Lower your back knee towards the ground, then push back up.",
    "isBodyweight": false,
    "searchKeywords": ["bulgarian split squat", "dumbbell", "legs", "glutes", "gym"]
  },
  {
    "name": "Farmers Walk",
    "category": "Strength, Core",
    "muscleGroup": "Arms", // Primarily grip and trapezius, but also core and legs for stability
    "equipment": "Heavy Dumbbells/Kettlebells",
    "instructions": "Hold heavy dumbbells or kettlebells in each hand, walk for a set distance or time, maintaining an upright posture.",
    "isBodyweight": false,
    "searchKeywords": ["farmers walk", "grip strength", "core", "full body", "gym"]
  },
  {
    "name": "Ab Rollout (Ab Wheel Barbell)", // Name modified
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "Ab Wheel or Barbell",
    "instructions": "From a kneeling position, roll the wheel or barbell forward, extending your body, then pull back using your core.",
    "isBodyweight": false, // Requires equipment
    "searchKeywords": ["ab rollout", "ab wheel", "abs", "core", "gym"]
  },
  {
    "name": "Kneeling Cable Crunch",
    "category": "Core",
    "muscleGroup": "Core",
    "equipment": "Cable Machine, Rope Attachment",
    "instructions": "Kneel in front of a high pulley, grasp the rope attachment. Pull the rope down towards the floor by flexing your abs, keeping hips still.",
    "isBodyweight": false,
    "searchKeywords": ["cable crunch", "abs", "core", "gym"]
  },
  {
    "name": "Machine Row (Seated)",
    "category": "Strength",
    "muscleGroup": "Back",
    "equipment": "Rowing Machine (Selectorized)",
    "instructions": "Sit at the machine, grasp handles. Pull handles towards your body, squeezing shoulder blades together, then slowly release.",
    "isBodyweight": false,
    "searchKeywords": ["machine row", "back", "gym"]
  },
  {
    "name": "Pec Deck Fly Machine",
    "category": "Strength",
    "muscleGroup": "Chest",
    "equipment": "Pec Deck Machine",
    "instructions": "Sit on the machine, place forearms against the pads. Bring the pads together in front of your chest, squeezing your pecs.",
    "isBodyweight": false,
    "searchKeywords": ["pec deck", "chest fly", "chest", "machine", "gym"]
  },
  {
    "name": "Preacher Curl Machine",
    "category": "Strength",
    "muscleGroup": "Arms",
    "equipment": "Preacher Curl Machine",
    "instructions": "Sit at the machine, rest upper arms on the pad. Grasp the handle and curl it upwards, squeezing your biceps, then lower slowly.",
    "isBodyweight": false,
    "searchKeywords": ["preacher curl", "biceps", "arms", "machine", "gym"]
  },
  {
    "name": "Standing Calf Raise (Machine)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Standing Calf Raise Machine",
    "instructions": "Stand on the machine with shoulders under pads. Raise up onto the balls of your feet, then lower slowly, stretching calves.",
    "isBodyweight": false,
    "searchKeywords": ["standing calf raise", "calves", "machine", "gym"]
  },
  {
    "name": "Seated Calf Raise (Machine)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Seated Calf Raise Machine",
    "instructions": "Sit on the machine, place knees under pad, balls of feet on platform. Raise heels up, then lower, stretching calves.",
    "isBodyweight": false,
    "searchKeywords": ["seated calf raise", "calves", "machine", "gym"]
  },
  {
    "name": "Adductor Machine",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Adductor Machine",
    "instructions": "Sit on the machine, place legs against the pads. Squeeze your legs together against the resistance.",
    "isBodyweight": false,
    "searchKeywords": ["adductor", "inner thigh", "legs", "machine", "gym"]
  },
  {
    "name": "Abductor Machine",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Abductor Machine",
    "instructions": "Sit on the machine, place legs against the pads. Push your legs outwards against the resistance.",
    "isBodyweight": false,
    "searchKeywords": ["abductor", "outer thigh", "glutes", "legs", "machine", "gym"]
  },
  {
    "name": "Cable Face Pulls",
    "category": "Strength",
    "muscleGroup": "Shoulder", // Primarily rear delts and upper back
    "equipment": "Cable Machine, Rope Attachment",
    "instructions": "Grasp a rope attachment from a high pulley. Pull the rope towards your face, externally rotating your shoulders.",
    "isBodyweight": false,
    "searchKeywords": ["face pull", "rear delts", "upper back", "shoulders", "gym"]
  },
  {
    "name": "Renegade Row",
    "category": "Strength, Core",
    "muscleGroup": "Back", // Also engages core heavily for stability
    "equipment": "Dumbbells",
    "instructions": "Start in a plank position with hands on dumbbells. Perform a single-arm row, pulling one dumbbell towards your hip while stabilizing your core.",
    "isBodyweight": false,
    "searchKeywords": ["renegade row", "back", "core", "stability", "dumbbell", "gym"]
  },
  {
    "name": "Single-Leg RDL (Romanian Deadlift) (Dumbbell)",
    "category": "Strength, Balance",
    "muscleGroup": "Legs",
    "equipment": "Dumbbell (optional)",
    "instructions": "Hold a dumbbell in one hand. Hinge at your hip, extending the opposite leg straight back for balance, lowering the dumbbell towards the floor. Return to standing.",
    "isBodyweight": false, // Can be done bodyweight, but typically with dumbbell
    "searchKeywords": ["single leg RDL", "hamstrings", "glutes", "balance", "dumbbell", "gym"]
  },
  {
    "name": "Sumo Squat (Dumbbell)",
    "category": "Strength",
    "muscleGroup": "Legs",
    "equipment": "Dumbbell",
    "instructions": "Stand with a wide stance, toes pointed outwards. Hold a dumbbell with both hands. Squat down, keeping your chest up and pushing knees out.",
    "isBodyweight": false,
    "searchKeywords": ["sumo squat", "dumbbell", "legs", "inner thigh", "glutes", "gym"]
  },
];

Future<void> uploadworkoutDatabase() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference workoutCollection = firestore.collection(
    'workouts',
  );

  for (final workout in workoutData) {
    try {
      final docId = workout['name']; // Using name as unique doc ID
      await workoutCollection.doc(docId).set(workout);
      print("✅ Uploaded: $docId");
    } catch (e) {
      print("❌ Error uploading ${workout['name']}: $e");
    }
  }

  print("🎉 All workout items uploaded successfully.");
}
