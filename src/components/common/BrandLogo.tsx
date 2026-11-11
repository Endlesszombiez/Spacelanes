import type { ImgHTMLAttributes } from 'react';
import { getBrandLogo } from '@/assets/branding';
import { useThemeStore } from '@/stores/useThemeStore';

type BrandLogoProps = Omit<ImgHTMLAttributes<HTMLImageElement>, 'src' | 'alt'>;

export function BrandLogo(props: BrandLogoProps) {
  const resolvedTheme = useThemeStore((state) => state.resolvedTheme);
  return <img {...props} src={getBrandLogo(resolvedTheme)} alt="" />;
}
