import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  final Map<String, dynamic> mealPlan;

  const ShoppingListScreen({Key? key, required this.mealPlan})
      : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Map<String, Map<String, dynamic>> groceryItems = {};
  Map<String, bool> checkedItems = {};
  List<int> selectedDays = []; // Hangi günler seçili
  String selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    // İlk 3 günü varsayılan olarak seç
    selectedDays = [0, 1, 2];
    _generateShoppingList();
  }

  void _generateShoppingList() {
    groceryItems.clear();

    // NULL KONTROLÜ VE YENİ FORMAT UYUMU
    final days = widget.mealPlan['days'] as List<dynamic>?;

    if (days == null || days.isEmpty) {
      // Veri yoksa boş liste göster
      setState(() {});
      return;
    }

    // Seçili günlerdeki yemekleri topla
    for (int dayIndex in selectedDays) {
      if (dayIndex >= days.length) continue;

      final day = days[dayIndex] as Map<String, dynamic>;
      final meals = day['meals'] as List<dynamic>? ?? [];

      for (var meal in meals) {
        final ingredients = meal['ingredients'] as List<dynamic>? ?? [];

        for (var ingredient in ingredients) {
          final name = ingredient['name']?.toString() ?? '';
          final amount = ingredient['amount']?.toString() ?? '0';
          final unit = ingredient['unit']?.toString() ?? '';

          if (name.isEmpty) continue;

          // Malzemeyi kategorize et
          final category = _categorizeIngredient(name.toLowerCase());

          // Miktarları topla
          if (groceryItems.containsKey(name)) {
            final existing = groceryItems[name]!;
            final existingAmount =
                double.tryParse(existing['amount'].toString()) ?? 0;
            final newAmount = double.tryParse(amount) ?? 0;

            groceryItems[name] = {
              'amount': (existingAmount + newAmount).toString(),
              'unit': unit,
              'category': category,
            };
          } else {
            groceryItems[name] = {
              'amount': amount,
              'unit': unit,
              'category': category,
            };
          }
        }
      }
    }

    setState(() {});
  }

  String _categorizeIngredient(String name) {
    // Protein
    if (name.contains('et') ||
        name.contains('tavuk') ||
        name.contains('balık') ||
        name.contains('yumurta') ||
        name.contains('peynir') ||
        name.contains('süt') ||
        name.contains('yoğurt') ||
        name.contains('protein')) {
      return 'Protein';
    }
    // Sebze
    else if (name.contains('domates') ||
        name.contains('salatalık') ||
        name.contains('marul') ||
        name.contains('biber') ||
        name.contains('soğan') ||
        name.contains('patates') ||
        name.contains('havuç') ||
        name.contains('brokoli') ||
        name.contains('sebze')) {
      return 'Sebze';
    }
    // Meyve
    else if (name.contains('elma') ||
        name.contains('muz') ||
        name.contains('portakal') ||
        name.contains('çilek') ||
        name.contains('meyve') ||
        name.contains('üzüm')) {
      return 'Meyve';
    }
    // Tahıl
    else if (name.contains('ekmek') ||
        name.contains('makarna') ||
        name.contains('pirinç') ||
        name.contains('bulgur') ||
        name.contains('yulaf') ||
        name.contains('un')) {
      return 'Tahıl';
    }
    // Yağ
    else if (name.contains('yağ') ||
        name.contains('zeytinyağı') ||
        name.contains('tereyağı') ||
        name.contains('fındık') ||
        name.contains('ceviz') ||
        name.contains('badem')) {
      return 'Yağlar';
    }
    // Baharat
    else if (name.contains('tuz') ||
        name.contains('karabiber') ||
        name.contains('baharat') ||
        name.contains('kimyon') ||
        name.contains('kekik')) {
      return 'Baharat';
    }
    // Diğer
    else {
      return 'Diğer';
    }
  }

  List<String> _getCategories() {
    final categories = <String>{'Tümü'};
    groceryItems.forEach((key, value) {
      categories.add(value['category']);
    });
    return categories.toList()..sort();
  }

  List<String> _getFilteredItems() {
    if (selectedCategory == 'Tümü') {
      return groceryItems.keys.toList()..sort();
    } else {
      return groceryItems.entries
          .where((entry) => entry.value['category'] == selectedCategory)
          .map((entry) => entry.key)
          .toList()
        ..sort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.mealPlan['days'] as List<dynamic>? ?? [];
    final categories = _getCategories();
    final filteredItems = _getFilteredItems();
    final checkedCount = checkedItems.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alışveriş Listesi'),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          if (checkedCount > 0)
            Center(
              child: Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$checkedCount / ${filteredItems.length}',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: days.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Beslenme planı bulunamadı!',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lütfen önce beslenme planı oluşturun.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Gün seçici
                Container(
                  color: Colors.purple,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hangi günler için alışveriş yapacaksınız?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(days.length, (index) {
                            final day = days[index] as Map<String, dynamic>;
                            final dayName = day['day'] ?? 'Gün ${index + 1}';
                            final isSelected = selectedDays.contains(index);

                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(dayName),
                                selected: isSelected,
                                selectedColor: Colors.white,
                                checkmarkColor: Colors.purple,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.purple : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: Colors.purple.shade300,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedDays.add(index);
                                    } else {
                                      selectedDays.remove(index);
                                    }
                                    selectedDays.sort();
                                    _generateShoppingList();
                                  });
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // Kategori seçici
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: Colors.purple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Liste boş kontrolü
                if (selectedDays.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Lütfen en az bir gün seçin',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredItems.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Bu kategoride ürün bulunamadı',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Alışveriş listesi
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final itemName = filteredItems[index];
                        final item = groceryItems[itemName]!;
                        final isChecked = checkedItems[itemName] ?? false;

                        return Card(
                          elevation: isChecked ? 0 : 2,
                          color:
                              isChecked ? Colors.green.shade50 : Colors.white,
                          margin: EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isChecked ? Colors.green : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              itemName,
                              style: TextStyle(
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: FontWeight.w500,
                                color: isChecked ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(item['category']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item['category'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${item['amount']} ${item['unit']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isChecked ? Colors.grey : Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            value: isChecked,
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            onChanged: (value) {
                              setState(() {
                                checkedItems[itemName] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: filteredItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _shareList,
              backgroundColor: Colors.purple,
              icon: Icon(Icons.share),
              label: Text('Paylaş'),
            )
          : null,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Protein':
        return Colors.red;
      case 'Sebze':
        return Colors.green;
      case 'Meyve':
        return Colors.orange;
      case 'Tahıl':
        return Colors.brown;
      case 'Yağlar':
        return Colors.amber;
      case 'Baharat':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  void _shareList() {
    final StringBuffer shareText = StringBuffer();

    shareText.writeln('🛒 Alışveriş Listesi');
    shareText.writeln(
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    shareText.writeln('');

    final categories = _getCategories();
    for (var category in categories) {
      if (category == 'Tümü') continue;

      final items = groceryItems.entries
          .where((e) => e.value['category'] == category)
          .toList();

      if (items.isEmpty) continue;

      shareText.writeln('📦 $category:');
      for (var item in items) {
        final check = checkedItems[item.key] ?? false ? '✅' : '⬜';
        shareText.writeln(
            '$check ${item.key} - ${item.value['amount']} ${item.value['unit']}');
      }
      shareText.writeln('');
    }

    // Share functionality buraya eklenebilir
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Liste Paylaşıldı'),
        content: SingleChildScrollView(
          child: Text(shareText.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
