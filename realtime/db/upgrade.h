#ifndef UPGRADE_H
#define UPGRADE_H

#include <string>
#include <ctime>

#include <boost/date_time/posix_time/ptime.hpp>

class Upgrade
{
public:
    Upgrade(): _releaseDate(boost::posix_time::not_a_date_time) {}

    inline void setVersion(const std::string &version) { _version = version; }
    inline const std::string& version() const { return _version; }

    inline void setChecksum(const std::string &checksum) { _checksum = checksum; }
    inline const std::string& checksum() const { return _checksum; }

    inline void setReleaseDate(const boost::posix_time::ptime &releaseDate) { _releaseDate = releaseDate; }
    inline const boost::posix_time::ptime& releaseDate() const { return _releaseDate; }

    inline void setBriedDescription(const std::string &briefDescription) { _briefDescription = briefDescription; }
    inline const std::string& briefDescription() const { return _briefDescription; }

    inline void setFullDescription(const std::string &fullDescription) { _fullDescription = fullDescription; }
    inline const std::string& fullDescription() const { return _fullDescription; }

private:
    std::string _version;
    std::string _checksum;
    boost::posix_time::ptime _releaseDate;
    std::string _briefDescription;
    std::string _fullDescription;
};

#endif // UPGRADE_H