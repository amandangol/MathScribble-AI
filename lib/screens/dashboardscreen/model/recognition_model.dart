enum RecognitionModel {
  gemini('Gemini 2.0 Model', 'Google\'s Gemini 2.0 flash model for recognition',
      'assets/images/geminimodel.png'),
  handwriting('MathHandwrit.ing Model', 'Cloud-based handwriting recognition',
      'assets/images/mathwriting.png');

  final String name;
  final String description;
  final String icon;
  const RecognitionModel(this.name, this.description, this.icon);
}
