export default function sum(nums: number[]) {
  return nums.reduce((acc, n) => acc + n, 0);
}
