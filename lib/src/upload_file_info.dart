import 'dart:io';


/**
 *  Describes the info of file to upload.
 */
class UploadFileInfo {
  UploadFileInfo(this.file, this.fileName, {this.contentType}):bytes=null;

  UploadFileInfo.fromBytes(this.bytes, this.fileName,{this.contentType}):file=null;

  /// The file to upload.
  final File file;

  /// The file content
  final List<int> bytes;

  /// The file name which the server will receive.
  final String fileName;

  /// The content-type of the upload file.
  ContentType contentType = ContentType.binary;
}
