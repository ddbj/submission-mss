import { filesize } from 'filesize';

export default function totalFileSize(files: { size: number }[]): string {
  return filesize(files.reduce((acc, f) => acc + f.size, 0));
}
