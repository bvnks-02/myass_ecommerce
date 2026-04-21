class FAQModel {
  final String question;
  final String answer;
  final String category;

  FAQModel({
    required this.question,
    required this.answer,
    this.category = 'General',
  });

  static List<FAQModel> getDummyFAQs() {
    return [
      FAQModel(
        question: 'How can I track my order?',
        answer: 'You can track your order by going to the Order History section in your Profile. Select the order you want to track to see its current status and delivery information.',
        category: 'Orders',
      ),
      FAQModel(
        question: 'What payment methods do you accept?',
        answer: 'We accept various payment methods including credit cards, debit cards, and cash on delivery. You can select your preferred payment method during checkout.',
        category: 'Payment',
      ),
      FAQModel(
        question: 'How do I cancel my order?',
        answer: 'Orders can be cancelled within 24 hours of placing them. Go to Order History, select the order, and tap on "Cancel Order". You will receive a confirmation once the cancellation is processed.',
        category: 'Orders',
      ),
      FAQModel(
        question: 'What is your return policy?',
        answer: 'We offer a 14-day return policy for all products. Items must be in their original condition with tags attached. Contact our support team to initiate a return.',
        category: 'Returns',
      ),
      FAQModel(
        question: 'How long does delivery take?',
        answer: 'Standard delivery takes 3-5 business days. Express delivery is available for 1-2 business delivery. Delivery times may vary based on your location.',
        category: 'Delivery',
      ),
      FAQModel(
        question: 'Do you offer warranty on watches?',
        answer: 'Yes, all our watches come with a 1-year manufacturer warranty. The warranty covers manufacturing defects but does not cover physical damage or water damage.',
        category: 'Warranty',
      ),
      FAQModel(
        question: 'How can I contact customer support?',
        answer: 'You can reach our customer support team via WhatsApp or email. We are available Monday to Saturday, 9 AM to 6 PM. Response time is usually within 24 hours.',
        category: 'Contact',
      ),
      FAQModel(
        question: 'Can I change my delivery address?',
        answer: 'Delivery address can be changed only before the order is shipped. Please contact our support team immediately with your order number and new address.',
        category: 'Orders',
      ),
    ];
  }
}
