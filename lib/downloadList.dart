// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:multilingual_dictionary/shared/data.dart';
import 'package:multilingual_dictionary/shared/LanguagesWithIcons.dart';

class DownloadLanguages extends StatefulWidget {
  final Function editLanguagesList;
  final List<String> downloadedLanguages;
  final DatabaseHelper databaseHelper;
  const DownloadLanguages(
      {super.key,
      required this.downloadedLanguages,
      required this.editLanguagesList,
      required this.databaseHelper});

  @override
  State<DownloadLanguages> createState() => _DownloadLanguagesState();
}

class _DownloadLanguagesState extends State<DownloadLanguages> {
  Map<String, Map<String, dynamic>> languagesData = {};

  download(String languageToDownload) async {
    setState(() {
      languagesData[languageToDownload]!["isLoading"] = true;
      languagesData[languageToDownload]!["size"] = 0;
    });

    void setProgressAndSize(num progress, int currentSize) {
      currentSize;
      setState(() {
        if (progress == 1) {
          // the download has finished and other processes are occuring
          // therefore a circular animation should appear
          languagesData[languageToDownload]!["progress"] = null;
          languagesData[languageToDownload]!["size"] = currentSize;
        } else {
          languagesData[languageToDownload]!["progress"] = progress;
          languagesData[languageToDownload]!["size"] = currentSize;
        }
      });
    }

    bool isSuccessful = await widget.databaseHelper
        .addLanguage(languageToDownload, setProgressAndSize);

    if (!isSuccessful) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'An error ocurred! Please check your internet connection')));

        setState(() {
          languagesData[languageToDownload]!["isLoading"] = false;
          languagesData[languageToDownload]!["size"] = null;
        });
      }
      return;
    }

    widget.editLanguagesList(addLang: languageToDownload);

    setState(() {
      languagesData[languageToDownload]!["isLoading"] = false;
      languagesData[languageToDownload]!["isDownloaded"] = true;
    });
  }

  delete(String languageToDelete) async {
    setState(() {
      languagesData[languageToDelete]!["isLoading"] = true;
      languagesData[languageToDelete]!["progress"] = null;
    });

    await widget.databaseHelper.deleteLanguage(languageToDelete);

    widget.editLanguagesList(removeLang: languageToDelete);

    widget.databaseHelper.userData.set(languageToDelete, "0");

    setState(() {
      languagesData[languageToDelete]!["isDownloaded"] = false;
      languagesData[languageToDelete]!["isLoading"] = false;
      languagesData[languageToDelete]!["size"] = null;
    });
  }

  @override
  void initState() {
    widget.databaseHelper.userData
        .getLanguageTablesSize()
        .then((data) => setState(() {
              for (String lang in data.keys) {
                int size = data[lang] == null ? 0 : data[lang]!;

                languagesData[lang] = {};
                languagesData[lang]!["size"] = size == 0 ? null : size;
                languagesData[lang]!["isDownloaded"] = true;
                // the provided size can be zero which means the databse was deleted
                // or null which means it was never downloaded
              }
            }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LanguagesWithIcons(
      databaseHelper: widget.databaseHelper,
      builder: (flags, data) => Scaffold(
          appBar: AppBar(
            title: const Text('Languages'),
          ),
          body: ListView.builder(
            itemCount: data["providedByKaikki"].length,
            itemBuilder: (context, index) {
              String language = data["providedByKaikki"][index];

              if (languagesData[language] == null) {
                languagesData[language] = {};
              }

              return ListTile(
                title: Text(language),
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black38, width: .3),
                ),
                leading: flags[language],
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(languagesData[language]!["size"] != null
                        ? '${languagesData[language]!["size"]} Mb '
                        : ""),
                    languagesData[language]?["isLoading"] == true
                        ? OutlinedButton(
                            child: SizedBox(
                                width: 15,
                                height: 15,
                                child:
                                    languagesData[language]!["progress"] != null
                                        ? LinearProgressIndicator(
                                            value: languagesData[language]![
                                                "progress"],
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary)
                                        : CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .tertiary)),
                            onPressed: () {
                              widget.databaseHelper.cancel(language);
                            },
                          )
                        : languagesData[language]!["isDownloaded"] == true
                            ? OutlinedButton(
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  semanticLabel: 'delete',
                                ),
                                onPressed: () => delete(language),
                              )
                            : OutlinedButton(
                                child: Icon(
                                  Icons.download,
                                  color: Theme.of(context).colorScheme.primary,
                                  semanticLabel: 'download',
                                ),
                                onPressed: () => download(language),
                              ),
                  ],
                ),
              );
            },
          )),
    );
  }
}
