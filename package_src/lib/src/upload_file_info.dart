import 'dart:io';

/// Describes the info of file to upload.
class UploadFileInfo {
  UploadFileInfo(this.file, this.fileName, {ContentType contentType})
      : bytes = null,
        this.contentType = contentType ?? ContentType.binary;

  UploadFileInfo.fromBytes(this.bytes, this.fileName, {ContentType contentType})
      : file = null,
        this.contentType = contentType ?? ContentType.binary;

  /// The file to upload.
  final File file;

  /// The file content
  final List<int> bytes;

  /// The file name which the server will receive.
  final String fileName;

  /// The content-type of the upload file. Default value is `ContentType.binary`
  ContentType contentType;
}
