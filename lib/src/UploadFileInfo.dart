import 'dart:io';

/**
 *  Describes the info of file to upload.
 */
class UploadFileInfo {
  UploadFileInfo(this.file, this.fileName, {this.contentType});

  /// The file to upload.
  File file;

  /// The file name which the server will receive.
  String fileName;

  /// The content-type of the upload file.
  ContentType contentType = ContentType.BINARY;
}