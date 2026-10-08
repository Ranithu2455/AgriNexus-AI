import enum


class SupplierProductType(str, enum.Enum):
    seeds = "seeds"
    fertilizer = "fertilizer"
    organic_fertilizer = "organic_fertilizer"
    pesticides = "pesticides"
    herbicides = "herbicides"
    farming_equipment = "farming_equipment"
    irrigation_equipment = "irrigation_equipment"
    other = "other"
