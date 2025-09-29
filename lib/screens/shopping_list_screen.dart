import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  final Map<String, dynamic> mealPlan;
  
  ShoppingListScreen({required this.mealPlan});
  
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Map<String, ShoppingItem> shoppingList = {};
  Map<String, bool> checkedItems = {};
  
  @override
  void initState() {
    super.initState();
    _generateShoppingList();
  }
  
  void _generateShoppingList() {
    // Tüm malzemeleri topla ve grupla
    widget.mealPlan['days'].forEach((day) {
      day['meals'].forEach((meal) {
        if (meal['ingredients'] != null) {
          for (String ingredient in meal['ingredients']) {
            _parseAndAddIngredient(ingredient);
          }
        }
      });
    });
  }
  
  void _parseAndAddIngredient(String ingredient) {
    // "200g tavuk göğsü" gibi stringleri parse et
    final regex = RegExp(r'(\d+)\s*(g|kg|ml|L|adet|tane|çay kaşığı|yemek kaşığı)?\s+(.+)');
    final match = regex.firstMatch(ingredient);
    
    if (match != null) {
      final amount = int.parse(match.group(1)!);
      final unit = match.group(2) ?? 'adet';
      final name = match.group(3)!.trim();
      
      if (shoppingList.containsKey(name)) {
        shoppingList[name]!.amount += amount;
      } else {
        shoppingList[name] = ShoppingItem(
          name: name,
          amount: amount,
          unit: unit,
          category: _categorizeItem(name),
        );
      }
    }
  }
  
  String _categorizeItem(String name) {
    final categories = {
      'Et & Balık': ['tavuk', 'dana', 'balık', 'somon', 'ton', 'köfte'],
      'Süt Ürünleri': ['süt', 'yoğurt', 'peynir', 'lor', 'ayran', 'kefir'],
      'Sebze': ['domates', 'salatalık', 'biber', 'soğan', 'patates', 'havuç'],
      'Meyve': ['elma', 'muz', 'portakal', 'çilek', 'kivi', 'üzüm'],
      'Baklagil & Tahıl': ['pirinç', 'makarna', 'bulgur', 'mercimek', 'nohut'],
      'Diğer': [],
    };
    
    for (var entry in categories.entries) {
      if (entry.value.any((item) => name.toLowerCase().contains(item))) {
        return entry.key;
      }
    }
    return 'Diğer';
  }
  
  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<ShoppingItem>>{};
    
    // Kategorilere göre grupla
    shoppingList.values.forEach((item) {
      groupedItems[item.category] ??= [];
      groupedItems[item.category]!.add(item);
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Alışveriş Listesi'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareList,
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _clearChecked,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: groupedItems.keys.length,
        itemBuilder: (context, index) {
          final category = groupedItems.keys.elementAt(index);
          final items = groupedItems[category]!;
          
          return Card(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(category), size: 20),
                      SizedBox(width: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ...items.map((item) => CheckboxListTile(
                  value: checkedItems[item.name] ?? false,
                  onChanged: (value) {
                    setState(() {
                      checkedItems[item.name] = value!;
                    });
                  },
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: checkedItems[item.name] == true
                        ? TextDecoration.lineThrough
                        : null,
                    ),
                  ),
                  subtitle: Text('${item.amount} ${item.unit}'),
                  dense: true,
                )).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomItem,
        label: Text('Ekle'),
        icon: Icon(Icons.add),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    final icons = {
      'Et & Balık': Icons.set_meal,
      'Süt Ürünleri': Icons.egg,
      'Sebze': Icons.eco,
      'Meyve': Icons.apple,
      'Baklagil & Tahıl': Icons.grain,
      'Diğer': Icons.shopping_basket,
    };
    return icons[category] ?? Icons.category;
  }
  
  void _shareList() {
    // WhatsApp veya mesaj olarak paylaş
    String listText = 'Alışveriş Listesi:\n\n';
    
    shoppingList.forEach((name, item) {
      if (!(checkedItems[name] ?? false)) {
        listText += '☐ ${item.amount} ${item.unit} ${item.name}\n';
      }
    });
    
    // Share package kullanarak paylaş
    // Share.share(listText);
  }
  
  void _clearChecked() {
    setState(() {
      checkedItems.removeWhere((key, value) => value == true);
    });
  }
  
  void _addCustomItem() {
    // Özel item ekleme dialogu
  }
}

class ShoppingItem {
  final String name;
  int amount;
  final String unit;
  final String category;
  
  ShoppingItem({
    required this.name,
    required this.amount,
    required this.unit,
    required this.category,
  });
}
