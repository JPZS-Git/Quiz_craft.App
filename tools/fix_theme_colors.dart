import 'dart:io';

void main() {
  final file = File('quiz_craft/lib/features/home/home_page.dart');
  var content = file.readAsStringSync();
  
  // Remove as constantes de cores hard-coded já foi feito
  
  // Substitui Colors.white no iconTheme do AppBar
  content = content.replaceAll(
    '        iconTheme: const IconThemeData(color: Colors.white),',
    '        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),',
  );
  
  // Substitui color: Colors.white no título do AppBar  
  content = content.replaceAll(
    RegExp(r'(\s+)color: Colors\.white,\s*\n(\s+)\),\s*\n(\s+)\),\s*\n(\s+)actions:'),
    r'$1color: Theme.of(context).colorScheme.onPrimary,' + '\n' + 
    r'$2),' + '\n' + r'$3),' + '\n' + r'$4actions:',
  );
  
  print('Substituições aplicadas!');
  file.writeAsStringSync(content);
}
