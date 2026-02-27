import ENV from 'mssform/config/environment';

export interface EnumEntry {
  key: string;
  label: string;
}

export default function enumEntries(key: string): EnumEntry[] {
  return ((ENV['enums'] as Record<string, unknown>)[key] as EnumEntry[] | undefined) ?? [];
}
