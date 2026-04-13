class PetSelection {
  String petPath = "homescreen_cat.svg";
  String pet;

  PetSelection({required this.pet}) {
    if (pet == "Dog") {
      petPath = "homescreen_dog.svg";
    } else if (pet == "Cat") {
      petPath = "homescreen_cat.svg";
    } else {
      petPath = "homescreen_dog.svg"; // fallback (optional)
    }
  }
}
