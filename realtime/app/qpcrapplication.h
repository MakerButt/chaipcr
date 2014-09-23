#ifndef _QPCRSERVER_H_
#define _QPCRSERVER_H_

#include <Poco/Util/ServerApplication.h>

#include <signal.h>
#include <atomic>
#include <memory>
#include <exception>

class IControl;
class IThreadControl;
class ExperimentController;

// Class QPCRApplication
class QPCRApplication: public Poco::Util::ServerApplication
{
public:
    inline static QPCRApplication& getInstance() { return static_cast<QPCRApplication&>(instance()); }

    inline bool isWorking() const { return _workState.load(); }
    inline void close() { _workState = false; }

    inline void setException(std::exception_ptr exception) { _exception = exception; }

protected:
	//from ServerApplication
    void initialize(Poco::Util::Application &self);
    int main(const std::vector<std::string> &args);

private:
    void initSignals();
    bool waitSignal() const;

private:
    sigset_t _signalsSet;

    std::atomic<bool> _workState;

    std::vector<std::shared_ptr<IControl>> _controlUnits;
    std::vector<std::shared_ptr<IThreadControl>> _threadControlUnits;
    std::shared_ptr<ExperimentController> _experimentController;

    std::exception_ptr _exception;
};

#define qpcrApp QPCRApplication::getInstance()

#endif
