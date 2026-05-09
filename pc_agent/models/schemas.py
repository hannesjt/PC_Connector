from pydantic import BaseModel, ConfigDict


class PcConfig(BaseModel):
    name: str
    mac_address: str


class ApiConfig(BaseModel):
    model_config = ConfigDict(extra="ignore")

    host: str = "0.0.0.0"
    port: int = 8420


class ScriptConfig(BaseModel):
    id: str
    name: str
    icon: str = "play_arrow"
    command: str
    confirm: bool = False
    timeout: int = 30
    group: str = ""
    order: int = 0
    is_global: bool = False


class AppConfig(BaseModel):
    pc: PcConfig
    api: ApiConfig
    scripts: list[ScriptConfig] = []
    category_order: list[str] = []


class PairingRequest(BaseModel):
    code: str
    device_name: str = "Unbekanntes Gerät"


class PairingResponse(BaseModel):
    success: bool
    token: str | None = None
    message: str = ""
    mac_address: str | None = None
    pc_name: str | None = None


class StatusResponse(BaseModel):
    status: str
    pc_name: str
    mac_address: str


class ScriptListItem(BaseModel):
    id: str
    name: str
    icon: str
    confirm: bool
    group: str = ""
    order: int = 0
    is_global: bool = False


class ChainStep(BaseModel):
    script_id: str
    delay_seconds: int = 0


class ScriptChain(BaseModel):
    id: str
    name: str
    steps: list[ChainStep] = []
    order: int = 0


class ScriptRunResponse(BaseModel):
    script_id: str
    success: bool
    stdout: str = ""
    stderr: str = ""
    exit_code: int = 0


class ReorderRequest(BaseModel):
    ordered_ids: list[str]


class AssignGroupRequest(BaseModel):
    group: str
    script_ids: list[str]
    old_group: str | None = None
