import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TagsSection extends StatelessWidget {
  final List<String> tags;
  final Set<String> selectedTags;
  final Function(String) onAddTag;
  final Function(String) onToggleTag;

  const TagsSection({
    Key? key,
    required this.tags,
    required this.selectedTags,
    required this.onAddTag,
    required this.onToggleTag,
  }) : super(key: key);

  Future<void> _showAddTagDialog(BuildContext context) async {
    final controller = TextEditingController();
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final remaining = 20 - controller.text.length;
            return AlertDialog(
              title: const Text('Add Tag', style: TextStyle(fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Tag name',
                      counterText: '',
                    ),
                    maxLength: 20,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$remaining/20',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty && text.length <= 20) {
                      Navigator.pop(context, text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newTag != null && newTag.isNotEmpty) {
      onAddTag(newTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -1,
                  vertical: -2,
                ),
              ),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Search'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map(
              (tag) => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onToggleTag(tag),
                child: IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selectedTags.contains(tag)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: selectedTags.contains(tag) ? 0 : 1,
                      ),
                    ),
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: selectedTags.contains(tag)
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showAddTagDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add tag'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -1,
                  vertical: -2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
