import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() async {
  group(MultipartFile, () {
    test(
      'fromFile sets correct content-type',
      () async {
        final mediaType = DioMediaType.parse('text/plain');
        final file = await MultipartFile.fromFile(
          'test/mock/_testfile',
          filename: '1.txt',
          contentType: mediaType,
        );
        expect(file.contentType, mediaType);
      },
      testOn: 'vm',
    );

    // Cloned multipart files should be able to be read again and be the same
    // as the original ones.
    test(
      'complex cloning MultipartFile',
      () async {
        final multipartFile1 = MultipartFile.fromString(
          'hello world.',
          headers: {
            'test': <String>['a'],
          },
        );
        final multipartFile2 = await MultipartFile.fromFile(
          'test/mock/_testfile',
          filename: '1.txt',
          headers: {
            'test': <String>['b'],
          },
        );
        final multipartFile3 = MultipartFile.fromFileSync(
          'test/mock/_testfile',
          filename: '2.txt',
          headers: {
            'test': <String>['c'],
          },
        );

        final fm = FormData.fromMap({
          'name': 'wendux',
          'age': 25,
          'path': '/图片空间/地址',
          'file': multipartFile1,
          'files': [
            multipartFile2,
            multipartFile3,
          ],
        });
        final fmStr = await fm.readAsBytes();

        // Files are finalized after being read.
        try {
          multipartFile1.finalize();
          fail('Should not be able to finalize a file twice.');
        } catch (e) {
          expect(e, isA<StateError>());
          expect(
            (e as StateError).message,
            'The MultipartFile has already been finalized. '
            'This typically means you are using the same MultipartFile '
            'in repeated requests.\n'
            'Use MultipartFile.clone() or create a new MultipartFile '
            'for further usages.',
          );
        }

        final fm1 = FormData();
        fm1.fields.add(const MapEntry('name', 'wendux'));
        fm1.fields.add(const MapEntry('age', '25'));
        fm1.fields.add(const MapEntry('path', '/图片空间/地址'));
        fm1.files.add(
          MapEntry(
            'file',
            multipartFile1.clone(),
          ),
        );
        fm1.files.add(
          MapEntry(
            'files',
            multipartFile2.clone(),
          ),
        );
        fm1.files.add(
          MapEntry(
            'files',
            multipartFile3.clone(),
          ),
        );
        expect(fmStr.length, fm1.length);

        // The cloned multipart files should be able to be read again.
        expect(fm.files[0].value.isFinalized, true);
        expect(fm.files[1].value.isFinalized, true);
        expect(fm.files[2].value.isFinalized, true);
        expect(fm1.files[0].value.isFinalized, false);
        expect(fm1.files[1].value.isFinalized, false);
        expect(fm1.files[2].value.isFinalized, false);

        // The cloned multipart files' properties should be the same as the
        // original ones.
        expect(fm1.files[0].value.filename, multipartFile1.filename);
        expect(fm1.files[0].value.contentType, multipartFile1.contentType);
        expect(fm1.files[0].value.length, multipartFile1.length);
        expect(fm1.files[0].value.headers, multipartFile1.headers);
      },
      testOn: 'vm',
    );
  });
}
