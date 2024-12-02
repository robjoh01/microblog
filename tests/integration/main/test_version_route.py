"""
Test route for version route, app/main/routes
"""

import tomllib
from bs4 import BeautifulSoup


def test_get_app_version(client):
    """
    Test that can edit user profile.
    """
    response = client.get("/version")
    assert response.status_code == 200

    with open(".cz.toml", "rb") as f:
        data = tomllib.load(f)
        app_version = data["tool"]["commitizen"]["version"]

        soup = BeautifulSoup(response.data, "html.parser")
        version_element = soup.find("code", {"data-testid": "version"})
        version = version_element.text.strip()

        assert version_element is not None, "Version element not found in the response."
        assert (
            version == app_version
        ), f"Expected version {app_version}, but got {version}."
