import paperRedLogo from './branding/paper-red.svg?inline';
import monoSlateLogo from './branding/mono-slate.svg?inline';
import type { ResolvedTheme } from '@/types';

export const APP_NAME = 'Spacelanes Proxy';

export const getBrandLogo = (theme: ResolvedTheme): string =>
  theme === 'dark' ? monoSlateLogo : paperRedLogo;
