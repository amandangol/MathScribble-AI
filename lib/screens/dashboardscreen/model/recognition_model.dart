enum RecognitionModel {
  gemini('Gemini 2.0 Model', 'Google\'s Gemini 2.0 flash model for recognition',
      '🤖'),
  handwriting(
      'MathHandwrit.ing Model', 'Cloud-based handwriting recognition', '✍️');

  final String name;
  final String description;
  final String emoji;
  const RecognitionModel(this.name, this.description, this.emoji);
}
