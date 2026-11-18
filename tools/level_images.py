"""Keep level image exporters aligned with the runtime asset folders."""
from pathlib import Path


ANIMATION_SHEETS = {
    'haul_driver_sheet', 'water_sheet', 'spearers', 'spearers_whole',
    'spear41_lean', 'spear41_lean_steps',
}


def image_path(directory, name):
    directory = Path(directory)
    if directory.name not in ('figures', 'animation'):
        directory /= 'animation' if name in ANIMATION_SHEETS else 'figures'
    directory.mkdir(parents=True, exist_ok=True)
    return directory / f'{name}.png'
